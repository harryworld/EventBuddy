use std::{
    collections::BTreeMap,
    ffi::CStr,
    fs,
    io::ErrorKind,
    path::{Path, PathBuf},
    process::Command,
    thread,
    time::{Duration, Instant},
};

use anyhow::{Context, Result, anyhow, bail};
use chrono::Utc;
use clap::{Args, Parser, Subcommand, ValueEnum};
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use uuid::Uuid;

const APP_GROUP_ID: &str = "group.com.buildwithharry.EventBuddy";
const MAC_APP_BUNDLE_ID: &str = "com.buildwithharry.EventBuddy";
const DATABASE_FILE_NAME: &str = "EventBuddy.sqlite";
const COMMANDS_DIR_NAME: &str = "CLICommands";

#[derive(Parser)]
#[command(name = "wwdcbuddy")]
#[command(about = "Read and update WWDCBuddy data from the command line")]
struct Cli {
    #[arg(long, global = true, env = "EVENTBUDDY_DATABASE_PATH")]
    database: Option<PathBuf>,
    #[arg(long, global = true)]
    json: bool,
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Event {
        #[command(subcommand)]
        command: EventCommand,
    },
    Friend {
        #[command(subcommand)]
        command: FriendCommand,
    },
    Relation {
        #[command(subcommand)]
        command: RelationCommand,
    },
    Path,
}

#[derive(Subcommand)]
enum EventCommand {
    List(ListFilter),
}

#[derive(Subcommand)]
enum FriendCommand {
    List(FriendListFilter),
    Get { friend_id: String },
    Update(FriendUpdateArgs),
}

#[derive(Subcommand)]
enum RelationCommand {
    List(RelationListFilter),
    Link(RelationMutationArgs),
    Unlink(RelationMutationArgs),
}

#[derive(Args)]
struct ListFilter {
    #[arg(long)]
    search: Option<String>,
    #[arg(long)]
    favorites: bool,
}

#[derive(Args)]
struct FriendListFilter {
    #[arg(long)]
    search: Option<String>,
    #[arg(long)]
    favorites: bool,
}

#[derive(Args)]
struct RelationListFilter {
    #[arg(long)]
    event_id: Option<String>,
    #[arg(long)]
    friend_id: Option<String>,
    #[arg(long, value_enum)]
    kind: Option<RelationshipKind>,
}

#[derive(Args)]
struct FriendUpdateArgs {
    friend_id: String,
    #[command(flatten)]
    changes: FriendChangeArgs,
    #[arg(long)]
    no_wait: bool,
    #[arg(long, default_value_t = 15)]
    timeout_seconds: u64,
}

#[derive(Args)]
struct RelationMutationArgs {
    event_id: String,
    friend_id: String,
    #[arg(long, value_enum, default_value_t = RelationshipKind::Attending)]
    kind: RelationshipKind,
    #[arg(long)]
    no_wait: bool,
    #[arg(long, default_value_t = 15)]
    timeout_seconds: u64,
}

#[derive(Args, Serialize)]
#[serde(rename_all = "camelCase")]
struct FriendChangeArgs {
    #[arg(long)]
    name: Option<String>,
    #[arg(long)]
    email: Option<String>,
    #[arg(long)]
    phone: Option<String>,
    #[arg(long)]
    job_title: Option<String>,
    #[arg(long)]
    company: Option<String>,
    #[arg(long)]
    notes: Option<String>,
    #[arg(long)]
    favorite: Option<bool>,
    #[arg(long = "social", value_parser = parse_social)]
    social_media_handles: Vec<(String, String)>,
    #[arg(long)]
    clear_social: bool,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, ValueEnum)]
#[serde(rename_all = "camelCase")]
enum RelationshipKind {
    Attending,
    Wish,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct EventRow {
    id: String,
    title: String,
    event_description: String,
    location: String,
    address: Option<String>,
    start_date: String,
    end_date: String,
    event_type: String,
    notes: Option<String>,
    requires_ticket: bool,
    requires_registration: bool,
    url: Option<String>,
    created_at: String,
    updated_at: String,
    is_attending: bool,
    original_timezone_identifier: Option<String>,
    is_custom_event: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct FriendRow {
    id: String,
    name: String,
    email: Option<String>,
    phone: Option<String>,
    job_title: Option<String>,
    company: Option<String>,
    social_media_handles: BTreeMap<String, String>,
    notes: Option<String>,
    created_at: String,
    updated_at: String,
    is_favorite: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct RelationRow {
    id: String,
    kind: RelationshipKind,
    event_id: String,
    event_title: Option<String>,
    friend_id: String,
    friend_name: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CommandEnvelope {
    id: String,
    created_at: String,
    kind: String,
    payload: Value,
}

#[derive(Deserialize)]
struct CommandResponse {
    status: String,
    message: String,
    payload: Option<Value>,
}

fn main() {
    if let Err(error) = run() {
        eprintln!("error: {error:#}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    let database_path = cli.database.clone().unwrap_or(default_database_path()?);

    match cli.command {
        Commands::Event { command } => match command {
            EventCommand::List(filter) => {
                let events = list_events(&database_path, &filter)?;
                if cli.json {
                    print_json(&events)?;
                } else {
                    print_table(
                        &["id", "title", "start", "location"],
                        events.into_iter().map(|event| {
                            vec![event.id, event.title, event.start_date, event.location]
                        }),
                    );
                }
            }
        },
        Commands::Friend { command } => match command {
            FriendCommand::List(filter) => {
                let friends = list_friends(&database_path, &filter)?;
                if cli.json {
                    print_json(&friends)?;
                } else {
                    print_table(
                        &["id", "name", "company", "title", "favorite"],
                        friends.into_iter().map(|friend| {
                            vec![
                                friend.id,
                                friend.name,
                                friend.company.unwrap_or_default(),
                                friend.job_title.unwrap_or_default(),
                                friend.is_favorite.to_string(),
                            ]
                        }),
                    );
                }
            }
            FriendCommand::Get { friend_id } => {
                let friend = get_friend(&database_path, &friend_id)?
                    .ok_or_else(|| anyhow!("friend not found: {friend_id}"))?;
                if cli.json {
                    print_json(&friend)?;
                } else {
                    print_friend(&friend);
                }
            }
            FriendCommand::Update(args) => {
                let changes = args.changes.into_payload()?;
                if changes.as_object().is_none_or(|object| object.is_empty()) {
                    bail!("pass at least one update field");
                }
                let response = queue_command(
                    "updateFriend",
                    json!({
                        "friendID": normalize_uuid(&args.friend_id)?,
                        "changes": changes,
                    }),
                    !args.no_wait,
                    Duration::from_secs(args.timeout_seconds),
                )?;
                print_command_response(response, cli.json)?;
            }
        },
        Commands::Relation { command } => match command {
            RelationCommand::List(filter) => {
                let relations = list_relations(&database_path, &filter)?;
                if cli.json {
                    print_json(&relations)?;
                } else {
                    print_table(
                        &["kind", "event", "friend", "id"],
                        relations.into_iter().map(|relation| {
                            vec![
                                format!("{:?}", relation.kind).to_lowercase(),
                                relation.event_title.unwrap_or(relation.event_id),
                                relation.friend_name.unwrap_or(relation.friend_id),
                                relation.id,
                            ]
                        }),
                    );
                }
            }
            RelationCommand::Link(args) => {
                let response = queue_command(
                    "linkFriendToEvent",
                    json!({
                        "eventID": normalize_uuid(&args.event_id)?,
                        "friendID": normalize_uuid(&args.friend_id)?,
                        "relationship": args.kind,
                    }),
                    !args.no_wait,
                    Duration::from_secs(args.timeout_seconds),
                )?;
                print_command_response(response, cli.json)?;
            }
            RelationCommand::Unlink(args) => {
                let response = queue_command(
                    "unlinkFriendFromEvent",
                    json!({
                        "eventID": normalize_uuid(&args.event_id)?,
                        "friendID": normalize_uuid(&args.friend_id)?,
                        "relationship": args.kind,
                    }),
                    !args.no_wait,
                    Duration::from_secs(args.timeout_seconds),
                )?;
                print_command_response(response, cli.json)?;
            }
        },
        Commands::Path => {
            if cli.json {
                print_json(&json!({ "database": database_path }))?;
            } else {
                println!("{}", database_path.display());
            }
        }
    }

    Ok(())
}

impl FriendChangeArgs {
    fn into_payload(self) -> Result<Value> {
        let mut object = serde_json::Map::new();
        insert_if_some(&mut object, "name", self.name)?;
        insert_if_some(&mut object, "email", self.email)?;
        insert_if_some(&mut object, "phone", self.phone)?;
        insert_if_some(&mut object, "jobTitle", self.job_title)?;
        insert_if_some(&mut object, "company", self.company)?;
        insert_if_some(&mut object, "notes", self.notes)?;
        insert_if_some(&mut object, "isFavorite", self.favorite)?;
        if self.clear_social {
            object.insert("clearSocial".to_string(), Value::Bool(true));
        }
        if !self.social_media_handles.is_empty() {
            let handles = self
                .social_media_handles
                .into_iter()
                .collect::<BTreeMap<_, _>>();
            object.insert(
                "socialMediaHandles".to_string(),
                serde_json::to_value(handles)?,
            );
        }
        Ok(Value::Object(object))
    }
}

fn insert_if_some<T: Serialize>(
    object: &mut serde_json::Map<String, Value>,
    key: &str,
    value: Option<T>,
) -> Result<()> {
    if let Some(value) = value {
        object.insert(key.to_string(), serde_json::to_value(value)?);
    }
    Ok(())
}

fn list_events(database_path: &Path, filter: &ListFilter) -> Result<Vec<EventRow>> {
    let connection = open_database(database_path)?;
    let mut sql = String::from(
        r#"
        SELECT id, title, eventDescription, location, address, startDate, endDate,
               eventType, notes, requiresTicket, requiresRegistration, url,
               createdAt, updatedAt, isAttending, originalTimezoneIdentifier, isCustomEvent
        FROM storedEvents
        "#,
    );
    let search = filter.search.as_ref().map(|term| format!("%{}%", term));
    let mut predicates = Vec::new();

    if search.is_some() {
        predicates.push("(title LIKE ?1 OR location LIKE ?1 OR eventDescription LIKE ?1)");
    }
    if filter.favorites {
        predicates.push("isAttending = 1");
    }

    if !predicates.is_empty() {
        sql.push_str("WHERE ");
        sql.push_str(&predicates.join(" AND "));
        sql.push(' ');
    }
    sql.push_str("ORDER BY startDate ASC, title COLLATE NOCASE ASC");

    let mut statement = connection.prepare(&sql)?;
    let rows = if let Some(search) = search {
        statement.query_map(params![search], event_from_row)?
    } else {
        statement.query_map([], event_from_row)?
    };

    rows.collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to list events")
}

fn list_friends(database_path: &Path, filter: &FriendListFilter) -> Result<Vec<FriendRow>> {
    let connection = open_database(database_path)?;
    let mut sql = String::from(
        r#"
        SELECT id, name, email, phone, jobTitle, company, socialMediaHandlesJSON,
               notes, createdAt, updatedAt, isFavorite
        FROM storedFriends
        "#,
    );

    let mut clauses = Vec::new();
    if filter.search.is_some() {
        clauses.push("(name LIKE ?1 OR company LIKE ?1 OR jobTitle LIKE ?1 OR notes LIKE ?1)");
    }
    if filter.favorites {
        clauses.push("isFavorite = 1");
    }
    if !clauses.is_empty() {
        sql.push_str("WHERE ");
        sql.push_str(&clauses.join(" AND "));
        sql.push(' ');
    }
    sql.push_str("ORDER BY name COLLATE NOCASE ASC");

    let search = filter.search.as_ref().map(|term| format!("%{}%", term));
    let mut statement = connection.prepare(&sql)?;
    let rows = if let Some(search) = search {
        statement.query_map(params![search], friend_from_row)?
    } else {
        statement.query_map([], friend_from_row)?
    };

    rows.collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to list friends")
}

fn get_friend(database_path: &Path, friend_id: &str) -> Result<Option<FriendRow>> {
    let connection = open_database(database_path)?;
    let normalized_id = normalize_uuid(friend_id)?;
    let mut statement = connection.prepare(
        r#"
        SELECT id, name, email, phone, jobTitle, company, socialMediaHandlesJSON,
               notes, createdAt, updatedAt, isFavorite
        FROM storedFriends
        WHERE lower(id) = lower(?1)
        "#,
    )?;

    match statement.query_row(params![normalized_id], friend_from_row) {
        Ok(friend) => Ok(Some(friend)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(error) => Err(error).context("failed to load friend"),
    }
}

fn list_relations(database_path: &Path, filter: &RelationListFilter) -> Result<Vec<RelationRow>> {
    let connection = open_database(database_path)?;
    let mut relations = Vec::new();
    if filter
        .kind
        .is_none_or(|kind| matches!(kind, RelationshipKind::Attending))
    {
        relations.extend(query_relations(
            &connection,
            "storedEventAttendees",
            RelationshipKind::Attending,
            filter,
        )?);
    }
    if filter
        .kind
        .is_none_or(|kind| matches!(kind, RelationshipKind::Wish))
    {
        relations.extend(query_relations(
            &connection,
            "storedEventWishes",
            RelationshipKind::Wish,
            filter,
        )?);
    }
    relations.sort_by(|left, right| {
        left.event_title
            .cmp(&right.event_title)
            .then(left.friend_title_key().cmp(&right.friend_title_key()))
    });
    Ok(relations)
}

fn query_relations(
    connection: &Connection,
    table: &str,
    kind: RelationshipKind,
    filter: &RelationListFilter,
) -> Result<Vec<RelationRow>> {
    let mut sql = format!(
        r#"
        SELECT relation.id, relation.eventID, event.title, relation.friendID, friend.name
        FROM "{table}" relation
        LEFT JOIN storedEvents event ON lower(event.id) = lower(relation.eventID)
        LEFT JOIN storedFriends friend ON lower(friend.id) = lower(relation.friendID)
        "#
    );

    let mut clauses = Vec::new();
    let mut values = Vec::new();
    if let Some(event_id) = &filter.event_id {
        clauses.push("lower(relation.eventID) = lower(?)");
        values.push(normalize_uuid(event_id)?);
    }
    if let Some(friend_id) = &filter.friend_id {
        clauses.push("lower(relation.friendID) = lower(?)");
        values.push(normalize_uuid(friend_id)?);
    }
    if !clauses.is_empty() {
        sql.push_str("WHERE ");
        sql.push_str(&clauses.join(" AND "));
        sql.push(' ');
    }

    let mut statement = connection.prepare(&sql)?;
    let rows = statement.query_map(rusqlite::params_from_iter(values), |row| {
        Ok(RelationRow {
            id: row.get(0)?,
            kind,
            event_id: row.get(1)?,
            event_title: row.get(2)?,
            friend_id: row.get(3)?,
            friend_name: row.get(4)?,
        })
    })?;

    rows.collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to list relations")
}

impl RelationRow {
    fn friend_title_key(&self) -> String {
        self.friend_name
            .clone()
            .unwrap_or_else(|| self.friend_id.clone())
    }
}

fn queue_command(kind: &str, payload: Value, wait: bool, timeout: Duration) -> Result<Value> {
    let command_id = Uuid::new_v4().to_string();
    let command_dir = command_root_dir()?;
    let inbox = command_dir.join("inbox");
    let outbox = command_dir.join("outbox");
    fs::create_dir_all(&inbox)?;
    fs::create_dir_all(&outbox)?;

    let envelope = CommandEnvelope {
        id: command_id.clone(),
        created_at: Utc::now().to_rfc3339(),
        kind: kind.to_string(),
        payload,
    };
    let body = serde_json::to_vec_pretty(&envelope)?;
    let final_path = inbox.join(format!("{command_id}.json"));
    let temporary_path = inbox.join(format!("{command_id}.json.tmp"));
    fs::write(&temporary_path, body)?;
    fs::rename(&temporary_path, &final_path)?;

    let _ = Command::new("/usr/bin/open")
        .args(["-b", MAC_APP_BUNDLE_ID])
        .status();

    if !wait {
        return Ok(json!({
            "id": command_id,
            "status": "queued",
            "message": "Command queued for WWDCBuddy. Open the Mac app to save and sync it."
        }));
    }

    wait_for_response(&outbox.join(format!("{command_id}.json")), timeout)
}

fn wait_for_response(path: &Path, timeout: Duration) -> Result<Value> {
    let started_at = Instant::now();
    while started_at.elapsed() < timeout {
        match fs::read(path) {
            Ok(data) => {
                let _ = fs::remove_file(path);
                let response: CommandResponse = serde_json::from_slice(&data)?;
                if response.status == "success" {
                    return Ok(json!({
                        "status": response.status,
                        "message": response.message,
                        "payload": response.payload,
                    }));
                }
                bail!("{}", response.message);
            }
            Err(error) if error.kind() == ErrorKind::NotFound => {
                thread::sleep(Duration::from_millis(250));
            }
            Err(error) => return Err(error).context("failed to read command response"),
        }
    }

    bail!("timed out waiting for WWDCBuddy to process the command")
}

fn open_database(database_path: &Path) -> Result<Connection> {
    Connection::open(database_path)
        .with_context(|| format!("failed to open database at {}", database_path.display()))
}

fn event_from_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<EventRow> {
    Ok(EventRow {
        id: row.get(0)?,
        title: row.get(1)?,
        event_description: row.get(2)?,
        location: row.get(3)?,
        address: row.get(4)?,
        start_date: row.get(5)?,
        end_date: row.get(6)?,
        event_type: row.get(7)?,
        notes: row.get(8)?,
        requires_ticket: row.get::<_, i64>(9)? != 0,
        requires_registration: row.get::<_, i64>(10)? != 0,
        url: row.get(11)?,
        created_at: row.get(12)?,
        updated_at: row.get(13)?,
        is_attending: row.get::<_, i64>(14)? != 0,
        original_timezone_identifier: row.get(15)?,
        is_custom_event: row.get::<_, i64>(16)? != 0,
    })
}

fn friend_from_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<FriendRow> {
    let handles_json: String = row.get(6)?;
    Ok(FriendRow {
        id: row.get(0)?,
        name: row.get(1)?,
        email: row.get(2)?,
        phone: row.get(3)?,
        job_title: row.get(4)?,
        company: row.get(5)?,
        social_media_handles: serde_json::from_str(&handles_json).unwrap_or_default(),
        notes: row.get(7)?,
        created_at: row.get(8)?,
        updated_at: row.get(9)?,
        is_favorite: row.get::<_, i64>(10)? != 0,
    })
}

fn default_database_path() -> Result<PathBuf> {
    Ok(app_group_dir()?.join(DATABASE_FILE_NAME))
}

fn command_root_dir() -> Result<PathBuf> {
    Ok(app_group_dir()?.join(COMMANDS_DIR_NAME))
}

fn app_group_dir() -> Result<PathBuf> {
    Ok(real_home_dir()?
        .join("Library")
        .join("Group Containers")
        .join(APP_GROUP_ID))
}

fn real_home_dir() -> Result<PathBuf> {
    unsafe {
        let passwd = libc::getpwuid(libc::getuid());
        if passwd.is_null() || (*passwd).pw_dir.is_null() {
            bail!("failed to resolve home directory for current user");
        }

        Ok(PathBuf::from(
            CStr::from_ptr((*passwd).pw_dir)
                .to_string_lossy()
                .into_owned(),
        ))
    }
}

fn normalize_uuid(value: &str) -> Result<String> {
    Ok(Uuid::parse_str(value)
        .with_context(|| format!("invalid UUID: {value}"))?
        .hyphenated()
        .to_string())
}

fn parse_social(value: &str) -> Result<(String, String), String> {
    let Some((platform, handle)) = value.split_once('=') else {
        return Err("expected platform=handle".to_string());
    };
    if platform.trim().is_empty() {
        return Err("social platform cannot be empty".to_string());
    }
    Ok((platform.trim().to_string(), handle.trim().to_string()))
}

fn print_json<T: Serialize>(value: &T) -> Result<()> {
    println!("{}", serde_json::to_string_pretty(value)?);
    Ok(())
}

fn print_command_response(response: Value, json_output: bool) -> Result<()> {
    if json_output {
        print_json(&response)
    } else {
        let message = response
            .get("message")
            .and_then(Value::as_str)
            .unwrap_or("command complete");
        println!("{message}");
        Ok(())
    }
}

fn print_friend(friend: &FriendRow) {
    println!("id: {}", friend.id);
    println!("name: {}", friend.name);
    print_optional("email", &friend.email);
    print_optional("phone", &friend.phone);
    print_optional("job title", &friend.job_title);
    print_optional("company", &friend.company);
    if !friend.social_media_handles.is_empty() {
        println!("social:");
        for (platform, handle) in &friend.social_media_handles {
            println!("  {platform}: {handle}");
        }
    }
    print_optional("notes", &friend.notes);
    println!("favorite: {}", friend.is_favorite);
    println!("updated: {}", friend.updated_at);
}

fn print_optional(label: &str, value: &Option<String>) {
    if let Some(value) = value {
        if !value.is_empty() {
            println!("{label}: {value}");
        }
    }
}

fn print_table<I>(headers: &[&str], rows: I)
where
    I: IntoIterator<Item = Vec<String>>,
{
    let rows: Vec<Vec<String>> = rows.into_iter().collect();
    let mut widths: Vec<usize> = headers.iter().map(|header| header.len()).collect();
    for row in &rows {
        for (index, value) in row.iter().enumerate() {
            widths[index] = widths[index].max(value.len());
        }
    }

    print_row(headers.iter().copied(), &widths);
    print_row(widths.iter().map(|width| "-".repeat(*width)), &widths);
    for row in rows {
        print_row(row, &widths);
    }
}

fn print_row<I, S>(values: I, widths: &[usize])
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    for (index, value) in values.into_iter().enumerate() {
        if index > 0 {
            print!("  ");
        }
        print!("{:<width$}", value.as_ref(), width = widths[index]);
    }
    println!();
}

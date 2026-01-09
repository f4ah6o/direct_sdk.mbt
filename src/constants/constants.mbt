// Protocol constants for Direct SDK
// Reference: direct-go-sdk/direct-go/events.go, constants.go

// === Protocol Constants ===

// API version

///|
pub const API_VERSION : String = "1.128"

// Default WebSocket endpoint

///|
pub const DEFAULT_ENDPOINT : String = "wss://api.direct4b.com/albero-app-server/api"

// MessagePack RPC message types

///|
pub const RPC_REQUEST : Int = 0

///|
pub const RPC_RESPONSE : Int = 1

// === Timeouts (milliseconds) ===

// Default interval between WebSocket ping messages

///|
pub const DEFAULT_PING_INTERVAL : Int = 45_000

// Default timeout for RPC requests

///|
pub const DEFAULT_REQUEST_TIMEOUT : Int = 30_000

// Timeout for WebSocket handshake

///|
pub const DEFAULT_HANDSHAKE_TIMEOUT : Int = 10_000

// === Buffer Sizes ===

// Buffer size for the Messages channel

///|
pub const DEFAULT_MESSAGE_CHANNEL_SIZE : Int = 100

// Buffer size for RPC result channels

///|
pub const DEFAULT_RESULT_CHANNEL_SIZE : Int = 1

// === Event Names ===
// Server-to-client notifications prefixed with "notify_"

// Connection events

///|
pub const EVENT_SESSION_CREATED : String = "session_created"

///|
pub const EVENT_SESSION_ERROR : String = "session_error"

///|
pub const EVENT_DATA_RECOVERED : String = "data_recovered"

///|
pub const EVENT_NOTIFICATION_ERROR : String = "notification_error"

///|
pub const EVENT_ERROR : String = "error"

///|
pub const EVENT_DECODE_ERROR : String = "decode_error"

///|
pub const EVENT_ACCESS_TOKEN_CHANGED : String = "access_token_changed"

// Message notifications

///|
pub const EVENT_NOTIFY_CREATE_MESSAGE : String = "notify_create_message"

///|
pub const EVENT_NOTIFY_DELETE_MESSAGE : String = "notify_delete_message"

// Talk/Room notifications

///|
pub const EVENT_NOTIFY_CREATE_GROUP_TALK : String = "notify_create_group_talk"

///|
pub const EVENT_NOTIFY_CREATE_PAIR_TALK : String = "notify_create_pair_talk"

///|
pub const EVENT_NOTIFY_ADD_TALKERS : String = "notify_add_talkers"

///|
pub const EVENT_NOTIFY_DELETE_TALKER : String = "notify_delete_talker"

///|
pub const EVENT_NOTIFY_UPDATE_TALK : String = "notify_update_talk"

// User/Friend notifications

///|
pub const EVENT_NOTIFY_ADD_FRIEND : String = "notify_add_friend"

///|
pub const EVENT_NOTIFY_DELETE_FRIEND : String = "notify_delete_friend"

///|
pub const EVENT_NOTIFY_ADD_ACQUAINTANCE : String = "notify_add_acquaintance"

///|
pub const EVENT_NOTIFY_ADD_ACQUAINTANCES : String = "notify_add_acquaintances"

///|
pub const EVENT_NOTIFY_UPDATE_USER : String = "notify_update_user"

// Domain notifications

///|
pub const EVENT_NOTIFY_JOIN_DOMAIN : String = "notify_join_domain"

///|
pub const EVENT_NOTIFY_LEAVE_DOMAIN : String = "notify_leave_domain"

///|
pub const EVENT_NOTIFY_ADD_DOMAIN_INVITE : String = "notify_add_domain_invite"

///|
pub const EVENT_NOTIFY_DELETE_DOMAIN_INVITE : String = "notify_delete_domain_invite"

// Attachment notifications

///|
pub const EVENT_NOTIFY_CREATE_ATTACHMENT : String = "notify_create_attachment"

///|
pub const EVENT_NOTIFY_DELETE_ATTACHMENT : String = "notify_delete_attachment"

// Note notifications

///|
pub const EVENT_NOTIFY_CREATE_NOTE : String = "notify_create_note"

///|
pub const EVENT_NOTIFY_UPDATE_NOTE : String = "notify_update_note"

///|
pub const EVENT_NOTIFY_DELETE_NOTE : String = "notify_delete_note"

// Favorite notifications

///|
pub const EVENT_NOTIFY_ADD_FAVORITE_TALK : String = "notify_add_favorite_talk"

///|
pub const EVENT_NOTIFY_DELETE_FAVORITE_TALK : String = "notify_delete_favorite_talk"

// Announcement notifications

///|
pub const EVENT_NOTIFY_CREATE_ANNOUNCEMENT : String = "notify_create_announcement"

///|
pub const EVENT_NOTIFY_DELETE_ANNOUNCEMENT : String = "notify_delete_announcement"

// Read status notifications

///|
pub const EVENT_NOTIFY_UPDATE_READ_STATUS : String = "notify_update_read_status"

///|
pub const EVENT_NOTIFY_UPDATE_TALK_STATUS : String = "notify_update_talk_status"

// Conference notifications

///|
pub const EVENT_NOTIFY_CREATE_CONFERENCE : String = "notify_create_conference"

///|
pub const EVENT_NOTIFY_CLOSE_CONFERENCE : String = "notify_close_conference"

///|
pub const EVENT_NOTIFY_CONFERENCE_PARTICIPANT_JOIN : String = "notify_conference_participant_join"

///|
pub const EVENT_NOTIFY_CONFERENCE_PARTICIPANT_REJECT : String = "notify_conference_participant_reject"

// === RPC Method Names ===

// Session methods

///|
pub const METHOD_CREATE_SESSION : String = "create_session"

///|
pub const METHOD_START_NOTIFICATION : String = "start_notification"

///|
pub const METHOD_RESET_NOTIFICATION : String = "reset_notification"

///|
pub const METHOD_UPDATE_LAST_USED_AT : String = "update_last_used_at"

// Authentication methods

///|
pub const METHOD_CREATE_ACCESS_TOKEN : String = "create_access_token"

///|
pub const METHOD_CREATE_ACCESS_TOKEN_BY_ID : String = "create_access_token_by_id"

///|
pub const METHOD_AUTHORIZE_DEVICE : String = "authorize_device"

// User methods

///|
pub const METHOD_GET_ME : String = "get_me"

///|
pub const METHOD_GET_USERS : String = "get_users"

///|
pub const METHOD_GET_PROFILE : String = "get_profile"

///|
pub const METHOD_UPDATE_USER : String = "update_user"

///|
pub const METHOD_UPDATE_PROFILE : String = "update_profile"

///|
pub const METHOD_GET_PRESENCES : String = "get_presences"

///|
pub const METHOD_GET_USER_IDENTIFIERS : String = "get_user_identifiers"

// Friend methods

///|
pub const METHOD_ADD_FRIEND : String = "add_friend"

///|
pub const METHOD_DELETE_FRIEND : String = "delete_friend"

///|
pub const METHOD_GET_FRIENDS : String = "get_friends"

///|
pub const METHOD_GET_ACQUAINTANCES : String = "get_acquaintances"

// Domain methods

///|
pub const METHOD_GET_DOMAINS : String = "get_domains"

///|
pub const METHOD_LEAVE_DOMAIN : String = "leave_domain"

///|
pub const METHOD_GET_DOMAIN_INVITES : String = "get_domain_invites"

///|
pub const METHOD_ACCEPT_DOMAIN_INVITE : String = "accept_domain_invite"

///|
pub const METHOD_DELETE_DOMAIN_INVITE : String = "delete_domain_invite"

///|
pub const METHOD_GET_DOMAIN_USERS : String = "get_domain_users"

///|
pub const METHOD_SEARCH_DOMAIN_USERS : String = "search_domain_users"

// Department methods

///|
pub const METHOD_GET_DEPARTMENT_TREE : String = "get_department_tree"

///|
pub const METHOD_GET_DEPARTMENT_USERS : String = "get_department_users"

///|
pub const METHOD_GET_DEPARTMENT_USER_COUNT : String = "get_department_user_count"

// Talk methods

///|
pub const METHOD_GET_TALKS : String = "get_talks"

///|
pub const METHOD_GET_TALK_STATUSES : String = "get_talk_statuses"

///|
pub const METHOD_CREATE_GROUP_TALK : String = "create_group_talk"

///|
pub const METHOD_CREATE_PAIR_TALK : String = "create_pair_talk"

///|
pub const METHOD_UPDATE_GROUP_TALK : String = "update_group_talk"

///|
pub const METHOD_ADD_TALKERS : String = "add_talkers"

///|
pub const METHOD_DELETE_TALKER : String = "delete_talker"

// Favorite methods

///|
pub const METHOD_ADD_FAVORITE_TALK : String = "add_favorite_talk"

///|
pub const METHOD_DELETE_FAVORITE_TALK : String = "delete_favorite_talk"

// Message methods

///|
pub const METHOD_GET_MESSAGES : String = "get_messages"

///|
pub const METHOD_CREATE_MESSAGE : String = "create_message"

///|
pub const METHOD_DELETE_MESSAGE : String = "delete_message"

///|
pub const METHOD_SCHEDULE_MESSAGE : String = "schedule_message"

///|
pub const METHOD_SEARCH_MESSAGES : String = "search_messages"

///|
pub const METHOD_SEARCH_MESSAGES_AROUND_DATE_TIME : String = "search_messages_around_datetime"

///|
pub const METHOD_GET_FAVORITE_MESSAGES : String = "get_favorite_messages"

///|
pub const METHOD_ADD_FAVORITE_MESSAGE : String = "add_favorite_message"

///|
pub const METHOD_DELETE_FAVORITE_MESSAGE : String = "delete_favorite_message"

///|
pub const METHOD_GET_SCHEDULED_MESSAGES : String = "get_scheduled_messages"

///|
pub const METHOD_DELETE_SCHEDULED_MESSAGE : String = "delete_scheduled_message"

///|
pub const METHOD_RESCHEDULE_MESSAGE : String = "reschedule_message"

///|
pub const METHOD_GET_AVAILABLE_MESSAGE_REACTIONS : String = "get_available_message_reactions"

///|
pub const METHOD_SET_MESSAGE_REACTION : String = "set_message_reaction"

///|
pub const METHOD_RESET_MESSAGE_REACTION : String = "reset_message_reaction"

///|
pub const METHOD_GET_MESSAGE_REACTION_USERS : String = "get_message_reaction_users"

// File & Attachment methods

///|
pub const METHOD_CREATE_UPLOAD_AUTH : String = "create_upload_auth"

///|
pub const METHOD_GET_ATTACHMENTS : String = "get_attachments"

///|
pub const METHOD_DELETE_ATTACHMENT : String = "delete_attachment"

///|
pub const METHOD_SEARCH_ATTACHMENTS : String = "search_attachments"

///|
pub const METHOD_CREATE_FILE_PREVIEW : String = "create_file_preview"

///|
pub const METHOD_GET_FILE_PREVIEW : String = "get_file_preview"

// Read status methods

///|
pub const METHOD_GET_READ_STATUS : String = "get_read_status"

// Push notification methods

///|
pub const METHOD_DISABLE_PUSH_NOTIFICATION : String = "disable_push_notification"

///|
pub const METHOD_ENABLE_PUSH_NOTIFICATION : String = "enable_push_notification"

// Announcement methods

///|
pub const METHOD_CREATE_ANNOUNCEMENT : String = "create_announcement"

///|
pub const METHOD_GET_ANNOUNCEMENTS : String = "get_announcements"

///|
pub const METHOD_GET_ANNOUNCEMENT_STATUSES : String = "get_announcement_statuses"

///|
pub const METHOD_GET_ANNOUNCEMENT_STATUS : String = "get_announcement_status"

///|
pub const METHOD_UPDATE_ANNOUNCEMENT_STATUS : String = "update_announcement_status"

// Conference/Call methods

///|
pub const METHOD_GET_CONFERENCES : String = "get_conferences"

///|
pub const METHOD_GET_CONFERENCE_PARTICIPANTS : String = "get_conference_participants"

///|
pub const METHOD_JOIN_CONFERENCE : String = "join_conference"

///|
pub const METHOD_LEAVE_CONFERENCE : String = "leave_conference"

///|
pub const METHOD_REJECT_CONFERENCE : String = "reject_conference"

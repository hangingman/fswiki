-- D1 Database Schema

-- pages table: Stores the latest version of wiki pages
CREATE TABLE pages (
    id TEXT PRIMARY KEY,
    title TEXT UNIQUE NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- revisions table: Stores historical revisions of wiki pages (TODO: Implement later)
-- CREATE TABLE revisions (
--     id TEXT PRIMARY KEY,
--     page_id TEXT NOT NULL,
--     content TEXT NOT NULL,
--     timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
--     editor TEXT, -- User who made the edit (TODO: Implement user authentication)
--     comment TEXT, -- Edit summary
--     FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
-- );

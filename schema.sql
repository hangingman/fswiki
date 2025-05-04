-- D1 Database Schema

-- pages table: Stores the latest version of wiki pages
CREATE TABLE pages (
    id TEXT PRIMARY KEY, -- UUID or similar unique identifier
    title TEXT UNIQUE NOT NULL, -- Wiki page title
    content TEXT NOT NULL, -- Latest content of the page
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, -- Timestamp of page creation
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP -- Timestamp of the latest update (corresponds to lastmodified in data_tbl)
);

-- revisions table: Stores historical revisions of wiki pages
CREATE TABLE revisions (
    id TEXT PRIMARY KEY, -- UUID or similar unique identifier for the revision
    page_id TEXT NOT NULL, -- Foreign key referencing the pages table
    content TEXT NOT NULL, -- Content of this revision
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP, -- Timestamp of this revision (corresponds to lastmodified in backup_tbl)
    editor TEXT, -- User who made the edit (TODO: Implement user authentication)
    comment TEXT, -- Edit summary
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);

-- Add a unique index on page_id and timestamp for revisions, similar to backup_tbl
CREATE UNIQUE INDEX idx_revisions_page_id_timestamp ON revisions (page_id, timestamp DESC);


-- attributes table: Stores page-specific attributes like freeze status and page level
CREATE TABLE attributes (
    id TEXT PRIMARY KEY, -- UUID or similar unique identifier
    page_id TEXT NOT NULL, -- Foreign key referencing the pages table
    key TEXT NOT NULL, -- Attribute key (e.g., 'freeze', 'page_level')
    value TEXT NOT NULL, -- Attribute value
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the last update to this attribute
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);

-- Add unique indexes on page_id and key, and key and page_id, similar to attr_tbl
CREATE UNIQUE INDEX idx_attributes_page_key ON attributes (page_id, key);
CREATE UNIQUE INDEX idx_attributes_key_page ON attributes (key, page_id);


-- access_logs table: Stores access log information for pages
CREATE TABLE access_logs (
    id TEXT PRIMARY KEY, -- UUID or similar unique identifier
    page_id TEXT NOT NULL, -- Foreign key referencing the pages table
    accessed_at TEXT DEFAULT CURRENT_TIMESTAMP, -- Timestamp of access (corresponds to datetime in access_tbl)
    remote_addr TEXT, -- IP address of the accessor
    referer TEXT, -- Referer URL
    user_agent TEXT, -- User agent string
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the log entry (corresponds to lastmodified in access_tbl)
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);

-- Add indexes on updated_at and page_id/accessed_at, similar to access_tbl
CREATE INDEX idx_access_logs_updated_at ON access_logs (updated_at DESC);
CREATE INDEX idx_access_logs_page_datetime ON access_logs (page_id, accessed_at DESC);

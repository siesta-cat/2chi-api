CREATE TABLE images (
	  id TEXT PRIMARY KEY, 
    url TEXT UNIQUE,
    status TEXT,
    tags JSONB
);

INSERT INTO images (id, url, status, tags) VALUES
  (
		'e9a618f8dbccbd29ff4df62bec051e45533ccceb',
    'testing.com',
    'unavailable',
    '["2girl", "sleeping"]'
	),
  (
		'5bba55db4d1b6bbb9e0b6d1eb3eca0fc3ef9a906',
    'testing.org',
    'available',
    '["2girl", "sleeping"]'
  ),
  (
		'3725e96f0e0d3f5e60bfa32e30aba597ad72b514',
    'testing.net',
    'consumed',
    '["2girl", "sleeping"]'
  );
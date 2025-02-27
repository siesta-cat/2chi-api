db = new Mongo().getDB("bot");

db.images.insert([
  {
    url: "testing.com",
    status: "unavailable",
    tags: ["2girl", "sleeping"],
  },
  {
    url: "testing.org",
    status: "available",
    tags: ["2girl", "sleeping"],
  },
  {
    url: "testing.net",
    status: "consumed",
    tags: ["2girl", "sleeping"],
  },
]);

db = db.getSiblingDB('rust_app_db');

db.createUser({
    user: 'app_user',
    pwd: 'DevPassword123',
    roles: [
        {
            role: 'readWrite',
            db: 'rust_app_db'
        }
    ]
});

db.createCollection('setplayers');
db.createCollection('setgames');
db.createCollection('setstats');

print('Database initialized: rust_app_db');

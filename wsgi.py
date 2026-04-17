# This file is used to run the Flask application using a WSGI server. It imports the app and db objects from the app module and creates the database tables if they do not already exist.
from app import app, db

with app.app_context():
    db.create_all()
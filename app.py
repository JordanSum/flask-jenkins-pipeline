from flask import Flask, render_template, redirect, request
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from dotenv import load_dotenv
load_dotenv()

import os
db_uri = os.environ.get('DATABASE_URL')

app = Flask(__name__)

# SQLAlchemy configuration
app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
db = SQLAlchemy(app)

# Row of data
class MyTask(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.String(200), nullable=False)
    complete = db.Column(db.Integer, default=0)
    created = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self) -> str:
        return f"Task {self.id}"

# Route to webpages
# Home page
@app.route('/', methods=['POST', 'GET'])
def index():
    # Add task
    if request.method == "POST":
        current_task = request.form['content']
        new_task = MyTask(content=current_task)
        try:
            db.session.add(new_task)
            db.session.commit()
            return redirect('/')
        except Exception as e:
            print(f"An error occurred while adding the task: {e}")
            return f"An error occurred while adding the task: {e}"

    # See all tasks
    else:
        tasks = MyTask.query.order_by(MyTask.created).all()
        return render_template('index.html', tasks=tasks)
    
#https://www.home.com/delete
# Delete task
@app.route("/delete/<int:id>")
def delete(id:int):
    delete_task = MyTask.query.get_or_404(id)
    try:
        db.session.delete(delete_task)
        db.session.commit()
        return redirect('/')
    except Exception as e:
        return f"An error occurred while deleting the task: {e}"
    
# Edit the task
@app.route("/edit/<int:id>", methods=['POST', 'GET'])
def edit(id:int):
    edit_task = MyTask.query.get_or_404(id)
    if request.method == "POST":
        edit_task.content = request.form['content']
        try:
            db.session.commit()
            return redirect('/')
        except Exception as e:
            return f"An error occurred while editing the task: {e}"
    else:
        return render_template('edit.html', task=edit_task)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000)
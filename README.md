# 🚗 Smart Carwash Service System

This project is a complete service system to connect customers with local carwash businesses. It manages the entire workflow, including customer orders, vehicle pickup and delivery, carwash service management, and admin validation.

Read the file below for a full explanation.

📄 [Project Documentation (PDF)](./Documentation.pdf)


## 👥 Authors

* Mohammadsadegh Bayati
* Hamidreza Khodabandehlou
* Saman Esmaeili
* Reza Abdollahi

## Project Repository

https://git.kntu.ac.ir/system-design-analysis/4041/team8/smart_carwash_service_system

---

## ⚙️ Backend Installation

This guide is for setting up the backend project on a new computer.

### 1\. Clone the Repository
First, get the project code from the repository.
```bash
git clone [https://git.kntu.ac.ir/system-design-analysis/4041/team8/smart_carwash_service_system](https://git.kntu.ac.ir/system-design-analysis/4041/team8/smart_carwash_service_system)
cd smart_carwash_service_system/Backend
```


### 2\. Create and Activate Virtual Environment

We use a virtual environment to keep project libraries separate.

```bash
# 1. Create the environment (only do this once)
python -m venv venv

# 2. Activate the environment (do this every time you start working)

# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate
```

After activating, your command prompt should show `(venv)` at the beginning.

### 3\. Install Required Libraries

Install all the project dependencies from the `requirements.txt` file.

```bash
# Make sure your (venv) is active
pip install -r requirements.txt
```

### 4\. Set Up Local Secrets (.env)

You must create your own `.env` file to store your database password. This file is **not** committed to git.

1.  In the `Backend` folder, create a new file named `.env`
2.  Add the following lines, filling in your own local password:
    ```ini
    # Django Secret Key (you can generate a new one)
    SECRET_KEY='django-insecure-your-own-key-here'

    # PostgreSQL Database Settings
    DB_NAME='smart_carwash_db'
    DB_USER='smart_carwash_user'
    DB_PASSWORD='your_local_postgres_password'
    ```

### 5\. Run the Database

Once your libraries are installed and your `.env` file is ready, run the database migrations to create all the tables.

```bash
# Make sure your (venv) is active
python manage.py migrate
```

### 6\. Run the Server

The backend setup is now complete. You can run the development server:

```bash
python manage.py runserver
```

-----

## 🧑‍💻 For Backend Developers

### Updating Dependencies (requirements.txt)

If you install a *new* package (e.g., `pip install some-new-library`), you **must** update the `requirements.txt` file so your teammates get it too.

Run this command *after* you install a new package:

```bash
# Make sure your (venv) is active
pip freeze > requirements.txt
```

Then, commit the updated `requirements.txt` file to git.

```
```



## link of site
https://carwash-pro.liara.run/



## backend deploy
cd Backend

liara deploy --app my-project-api --platform docker --port 8000



## frontend deploy
cd Frontend/carwash_front

liara deploy --app carwash-pro --platform docker --port 80

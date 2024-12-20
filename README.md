# breakitDown

WebApp in Python to analyze PDF files.

## Project Structure

```
breakitDown/
├── .env
├── .gitignore
├── app.py
├── src
│   ├── PDFcontroller.py
│   ├── database.py
│   └── PDFmodel.py
├── static
└── templates
    ├── index.html
    └── summary.html
```

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/jalknToth/breakitDown.git
   ```

2. **Run the setup script:**

   ```bash
   chmod +x run.sh
   ./run.sh
   ```
   This script will:
   - Create the project directory structure.
   - Generate the `.env` file.  **Important:**  Edit the `.env` file with your MySQL credentials.
   - Create a virtual environment and install the required dependencies.
   - Create the database and tables in MySQL.
   - Set appropriate file permissions.

3. **Run the application:**

   ```bash
   flask run
   ```

## Usage

1. Open your web browser and navigate to `http://127.0.0.1:5000/`.
2. Upload a PDF file.
3. The application will extract the text, generate a summary, and display it on the page.

## Dependencies

- Flask
- mysql-connector-python
- PyPDF4

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.





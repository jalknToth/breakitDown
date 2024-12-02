from flask import Flask
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

def create_app():
    app = Flask(__name__, template_folder='templates')
    
    # Configuration from .env
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
    app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER')
    
    # Import and register blueprints
    from src.PDFcontroller import PDFroutes
    app.register_blueprint(PDFroutes)

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)

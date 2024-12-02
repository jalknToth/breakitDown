import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class DatabaseConnection:
    @classmethod
    def get_connection(cls):
        try:
            connection = mysql.connector.connect(
                host=os.getenv('DB_HOST', 'localhost'),
                user=os.getenv('DB_USER'),
                password=os.getenv('DB_PASSWORD'),
                database=os.getenv('DB_NAME')
            )
            return connection
        except Error as e:
            print(f"Error connecting to MySQL database: {e}")
            return None

    @classmethod
    def test_connection(cls):
        try:
            connection = cls.get_connection()
            if connection:
                cursor = connection.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                print("✅ Database connection successful!")
                cursor.close()
                connection.close()
                return True
        except Error as e:
            print(f"❌ Database connection failed: {e}")
            return False

    @classmethod
    def create_tables(cls):
        try:
            connection = cls.get_connection()
            if connection:
                cursor = connection.cursor()
                cursor.execute("SHOW TABLES LIKE 'pdfs'")
                result = cursor.fetchone()
                if not result: 
                
                    # Create PDF Summaries Table
                    create_table_query = """
                    CREATE TABLE IF NOT EXISTS pdfs (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        filename VARCHAR(255) NOT NULL,
                        summary TEXT,
                        extracted_text LONGTEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
                    """
                    
                    cursor.execute(create_table_query)
                    connection.commit()
                    print("✅ Tables created successfully!")
                
                cursor.close()
                connection.close()
                return True
        except Error as e:
            print(f"❌ Error creating tables: {e}")
            return False

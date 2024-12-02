from flask import Blueprint, render_template, request, redirect, url_for
from werkzeug.utils import secure_filename
import os
from src.PDFmodel import PDFModel

PDFroutes = Blueprint('PDFroutes', __name__)

@PDFroutes.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@PDFroutes.route('/upload', methods=['POST'])
def upload_pdf():
    if 'file' not in request.files:
        return redirect(url_for('PDFroutes.index'))
    
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('PDFroutes.index'))
    
    if file and file.filename.lower().endswith('.pdf'):
        filename = secure_filename(file.filename)
        filepath = os.path.join('uploads', filename)
        file.save(filepath)
        
        # Extract text and generate summary
        text = PDFModel.extract_text_from_pdf(filepath)
        if text:
            summary = PDFModel.generate_summary(text)
            
            # Save summary to database
            PDFModel.save_summary_to_db(filename, summary, text)
            
            return render_template('summary.html', summary=summary, filename=filename)
    
    return redirect(url_for('PDFroutes.index'))

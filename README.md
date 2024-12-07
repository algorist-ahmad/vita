# Vita  

Vita is a command-line job application management system designed to simplify and streamline the application process. With Vita, you can easily manage job applications, tailor resumes for specific positions, maintain a comprehensive portfolio of your achievements, and render professional resumes in PDF format—all from the terminal.

## Features  

- **Job Application Management**  
  Track and manage job applications with ease. Create, update, list, and delete job applications. Attach tailored resumes to specific applications and track their statuses.  

- **Centralized Resume Management**  
  Maintain a master CV containing all your experiences, education, and certifications. Generate job-specific resumes by filtering the master CV, using templates, or duplicating existing resumes.  

- **PDF Resume Rendering**  
  Convert YAML-formatted resumes into professional PDF documents using customizable templates.  

- **Resume Templates**  
  Create, edit, and manage resume templates to match various job requirements.  

- **Document Management**  
  Organize and manage supplementary documents like cover letters, certificates, and references. Link these to specific job applications.  

- **Portfolio Management**  
  Query and edit the master CV using `yq`. Add entries for new experiences, certifications, or other portfolio elements.  

- **Statistics**  
  Analyze your job applications and resumes with built-in statistics tracking.  

## Usage  

Run `vita help` to see a list of commands and their descriptions:  
```  
vita help  
```  

### Example Commands  

1. **Create a new job application:**  
   ```  
   vita job create --title "Software Engineer" --company "TechCorp"  
   ```  

2. **Create a tailored resume from a template:**  
   ```  
   vita cv create --from template modern --name "Tech Resume"  
   ```  

3. **Render a resume to PDF:**  
   ```  
   vita render 123abc --template modern --output ~/Documents/resumes/tech_resume.pdf  
   ```  

4. **Add a new certification to your master CV:**  
   ```  
   vita cv add --type certification --content "AWS Certified Solutions Architect"  
   ```  

5. **Query your master CV for education after 2020:**  
   ```  
   vita cv query '.education[] | select(.year >= 2020)'  
   ```  

## Contributing

This is an incomplete project for my own use. Expect nothing.

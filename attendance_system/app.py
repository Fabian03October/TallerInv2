from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector
from mysql.connector import Error
import bcrypt
import os
import re
from datetime import datetime
import calendar


app = Flask(__name__, template_folder='templates', static_folder='static')
app.secret_key = 'hola'  # Cambia esto por una clave segura en producción

# Database configuration
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Castillejos16&',
    'database': 'attendance_control'
}

# Function to connect to the database
def get_db_connection():
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error conectando a MySQL: {e}")
        return None

# Root route to redirect to login
@app.route('/')
def index():
    return redirect(url_for('login'))

# Register Teacher
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        email = request.form['email']
        password = request.form['password']
        
        # Hash the password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        connection = get_db_connection()
        if connection:
            try:
                cursor = connection.cursor()
                query = """INSERT INTO Teachers (first_name, last_name, email, password_hash)
                           VALUES (%s, %s, %s, %s)"""
                cursor.execute(query, (first_name, last_name, email, password_hash))
                connection.commit()
                cursor.close()
                connection.close()
                flash('Registro exitoso. Por favor, inicia sesión.', 'success')
                return redirect(url_for('login'))
            except Error as e:
                print(f"Error: {e}")
                flash('Error al registrar. El correo ya existe o hubo un problema.', 'error')
                return redirect(url_for('register'))
        else:
            flash('Error de conexión a la base de datos.', 'error')
            return redirect(url_for('register'))
    return render_template('register.html')

# Login Teacher
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        connection = get_db_connection()
        if connection:
            try:
                cursor = connection.cursor()
                query = "SELECT teacher_id, first_name, last_name, password_hash FROM Teachers WHERE email = %s"
                cursor.execute(query, (email,))
                teacher = cursor.fetchone()
                cursor.close()
                connection.close()
                
                if teacher and bcrypt.checkpw(password.encode('utf-8'), teacher[3].encode('utf-8')):
                    session['teacher_id'] = teacher[0]
                    session['teacher_name'] = f"{teacher[1]} {teacher[2]}"
                    flash('Inicio de sesión exitoso.', 'success')
                    return redirect(url_for('home'))
                else:
                    flash('Correo o contraseña incorrectos.', 'error')
                    return redirect(url_for('login'))
            except Error as e:
                print(f"Error: {e}")
                flash('Error al iniciar sesión.', 'error')
                return redirect(url_for('login'))
        else:
            flash('Error de conexión a la base de datos.', 'error')
            return redirect(url_for('login'))
    return render_template('login.html')

# Home Page (accessible only after login)
@app.route('/home')
def home():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    
    teacher_id = session['teacher_id']
    connection = get_db_connection()
    groups = []
    if connection:
        try:
            cursor = connection.cursor()
            query = "SELECT group_id, group_name FROM Grupos WHERE teacher_id = %s"
            cursor.execute(query, (teacher_id,))
            groups = cursor.fetchall()
            cursor.close()
            connection.close()
        except Error as e:
            print(f"Error: {e}")
            flash('Error al cargar los grupos.', 'error')
    
    return render_template('home.html', teacher_name=session['teacher_name'], groups=groups)

# Logout
@app.route('/logout')
def logout():
    session.pop('teacher_id', None)
    session.pop('teacher_name', None)
    flash('Has cerrado sesión.', 'success')
    return redirect(url_for('login'))


@app.route('/groups')
def groups():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    
    teacher_id = session['teacher_id']
    connection = get_db_connection()
    groups_data = []
    
    if connection:
        try:
            cursor = connection.cursor()
            
            # Obtener los grupos del profesor
            query_groups = """
                SELECT group_id, group_name, materia 
                FROM Grupos 
                WHERE teacher_id = %s
            """
            cursor.execute(query_groups, (teacher_id,))
            groups = cursor.fetchall()
            
            for group in groups:
                group_id = group[0]
                
                # Contar estudiantes por grupo
                query_students = """
                    SELECT COUNT(*) 
                    FROM Users 
                    WHERE group_id = %s
                """
                cursor.execute(query_students, (group_id,))
                num_students = cursor.fetchone()[0] or 0
                
                # Obtener sesiones de clase para calcular asistencia y determinar el horario
                query_sessions = """
                    SELECT session_id, session_date, start_time, end_time 
                    FROM Class_Sessions 
                    WHERE group_id = %s
                """
                cursor.execute(query_sessions, (group_id,))
                sessions = cursor.fetchall()
                
                # Calcular asistencia promedio
                total_attendance = 0
                total_sessions = len(sessions)
                if total_sessions > 0 and num_students > 0:
                    for session in sessions:
                        session_id = session[0]
                        query_attendance = """
                            SELECT status, COUNT(*) 
                            FROM Attendance 
                            WHERE session_id = %s 
                            GROUP BY status
                        """
                        cursor.execute(query_attendance, (session_id,))
                        attendance_counts = cursor.fetchall() or []
                        
                        present_count = 0
                        for status, count in attendance_counts:
                            if status == 'PRESENT':
                                present_count += count
                        
                        # Calcular porcentaje de asistencia para esta sesión
                        session_attendance = (present_count / num_students) * 100 if num_students > 0 else 0
                        total_attendance += session_attendance
                    
                    # Promedio de asistencia para el grupo
                    avg_attendance = round(total_attendance / total_sessions, 1) if total_sessions > 0 else 0
                else:
                    avg_attendance = 0
                
                # Determinar el horario y los días de la semana
                if sessions:
                    # Agrupar sesiones por horario para detectar patrones de días
                    schedule_dict = {}
                    for session in sessions:
                        session_date = session[1]  # session_date (date)
                        start_time = session[2].strftime("%H:%M")  # start_time (time)
                        end_time = session[3].strftime("%H:%M")  # end_time (time)
                        # Obtener el día de la semana (Lun, Mar, etc.)
                        day_name = calendar.day_name[session_date.weekday()][:3]  # Ej. "Wed" -> "Wed"
                        day_name = {"Mon": "Lun", "Tue": "Mar", "Wed": "Mié", "Thu": "Jue", "Fri": "Vie", "Sat": "Sáb", "Sun": "Dom"}[day_name]
                        
                        time_key = f"{start_time}-{end_time}"
                        if time_key not in schedule_dict:
                            schedule_dict[time_key] = set()
                        schedule_dict[time_key].add(day_name)
                    
                    # Formatear el horario
                    if schedule_dict:
                        # Tomar el primer horario como ejemplo (puedes ajustar para manejar múltiples horarios)
                        time_key = list(schedule_dict.keys())[0]
                        days = sorted(schedule_dict[time_key])
                        start_time, end_time = time_key.split("-")
                        if len(days) == 5 and days == ["Lun", "Mar", "Mié", "Jue", "Vie"]:
                            schedule = f"Lun-Vie {start_time} - {end_time}"
                        else:
                            days_str = "-".join(days)
                            schedule = f"{days_str} {start_time} - {end_time}"
                    else:
                        schedule = "No asignado"
                else:
                    schedule = "No asignado"
                
                # Añadir los datos al grupo
                groups_data.append({
                    'group_id': group_id,
                    'group_name': group[1],
                    'materia': group[2],
                    'num_students': num_students,
                    'avg_attendance': avg_attendance,
                    'schedule': schedule
                })
            
            cursor.close()
            connection.close()
        except Error as e:
            print(f"Error: {e}")
            flash('Error al cargar los grupos.', 'error')
    
    return render_template('groups.html', teacher_name=session['teacher_name'], groups=groups_data)


@app.route('/add_group', methods=['GET', 'POST'])
def add_group():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        group_name = request.form['group_name'].strip()
        materia = request.form['materia'].strip()
        semestre = request.form.get('semestre', '').strip()  # Opcional
        carrera = request.form.get('carrera', '').strip()    # Opcional
        descripcion = request.form.get('descripcion', '').strip()  # Opcional
        teacher_id = session['teacher_id']
        
        # Manejar materia personalizada si se selecciona "Otra"
        if materia == 'Otra':
            custom_materia = request.form.get('custom_materia_name', '').strip()
            if not custom_materia:
                flash('Por favor especifica el nombre de la materia.', 'error')
                return redirect(url_for('add_group'))
            materia = custom_materia
        
        # Validar el formato del group_name (número seguido de letras, ej. 4sb, 3ar)
        if not re.match(r'^\d+[A-Za-z]{1,2}$', group_name):
            flash('El nombre del grupo debe tener el formato número seguido de letras (ej. 4sb, 3ar).', 'error')
            return redirect(url_for('add_group'))
        
        connection = get_db_connection()
        if connection:
            try:
                cursor = connection.cursor()
                query = """INSERT INTO Grupos (group_name, materia, Semestre, carrera, descripcion, teacher_id, created_at)
                           VALUES (%s, %s, %s, %s, %s, %s, NOW())"""
                cursor.execute(query, (group_name, materia, semestre, carrera, descripcion, teacher_id))
                connection.commit()
                cursor.close()
                connection.close()
                flash('Grupo creado exitosamente.', 'success')
                return redirect(url_for('groups'))
            except Error as e:
                print(f"Error: {e}")
                flash('Error al crear el grupo. Asegúrate de que el nombre del grupo sea único.', 'error')
                return redirect(url_for('add_group'))
        else:
            flash('Error de conexión a la base de datos.', 'error')
            return redirect(url_for('add_group'))
    
    return render_template('add_group.html')

@app.route('/schedules')
def schedules():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    return render_template('home.html')  # Temporal

@app.route('/reports')
def reports():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    return render_template('home.html')  # Temporal

@app.route('/settings')
def settings():
    if 'teacher_id' not in session:
        flash('Por favor, inicia sesión primero.', 'error')
        return redirect(url_for('login'))
    return render_template('home.html')  # Temporal

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
    
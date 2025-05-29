-- MySQL dump 10.13  Distrib 8.0.36, for Linux (x86_64)
--
-- Host: localhost    Database: attendance_control
-- ------------------------------------------------------
-- Server version	8.4.5

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Attendance`
--

DROP TABLE IF EXISTS `Attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Attendance` (
  `attendance_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `session_id` int NOT NULL,
  `status` enum('PRESENT','ABSENT','LATE') NOT NULL,
  `scan_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`attendance_id`),
  KEY `idx_attendance_session` (`session_id`),
  KEY `idx_attendance_user` (`user_id`),
  CONSTRAINT `Attendance_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `Attendance_ibfk_2` FOREIGN KEY (`session_id`) REFERENCES `Class_Sessions` (`session_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Attendance`
--

LOCK TABLES `Attendance` WRITE;
/*!40000 ALTER TABLE `Attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `Attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Class_Sessions`
--

DROP TABLE IF EXISTS `Class_Sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Class_Sessions` (
  `session_id` int NOT NULL AUTO_INCREMENT,
  `group_id` int NOT NULL,
  `session_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`session_id`),
  KEY `group_id` (`group_id`),
  CONSTRAINT `Class_Sessions_ibfk_1` FOREIGN KEY (`group_id`) REFERENCES `Grupos` (`group_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Class_Sessions`
--

LOCK TABLES `Class_Sessions` WRITE;
/*!40000 ALTER TABLE `Class_Sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `Class_Sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Grupos`
--

DROP TABLE IF EXISTS `Grupos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Grupos` (
  `group_id` int NOT NULL AUTO_INCREMENT,
  `group_name` varchar(50) NOT NULL,
  `materia` varchar(50) NOT NULL,
  `Semestre` varchar(12) NOT NULL,
  `carrera` varchar(50) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `teacher_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`group_id`),
  KEY `teacher_id` (`teacher_id`),
  CONSTRAINT `Grupos_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `Teachers` (`teacher_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Grupos`
--

LOCK TABLES `Grupos` WRITE;
/*!40000 ALTER TABLE `Grupos` DISABLE KEYS */;
INSERT INTO `Grupos` VALUES (1,'2SC','matematicas discretas','','','',1,'2025-05-27 22:37:02'),(2,'2sb','toma de decisiones','','','',1,'2025-05-27 22:47:51'),(3,'3rt','Redes','7','Sistemas Computacionales','mataeria de redes de computacion',1,'2025-05-28 15:21:56');
/*!40000 ALTER TABLE `Grupos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Reports`
--

DROP TABLE IF EXISTS `Reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Reports` (
  `report_id` int NOT NULL AUTO_INCREMENT,
  `teacher_id` int NOT NULL,
  `group_id` int NOT NULL,
  `report_date` date NOT NULL,
  `report_content` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  KEY `idx_reports_teacher` (`teacher_id`),
  KEY `idx_reports_group` (`group_id`),
  CONSTRAINT `Reports_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `Teachers` (`teacher_id`) ON DELETE CASCADE,
  CONSTRAINT `Reports_ibfk_2` FOREIGN KEY (`group_id`) REFERENCES `Grupos` (`group_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Reports`
--

LOCK TABLES `Reports` WRITE;
/*!40000 ALTER TABLE `Reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `Reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Teachers`
--

DROP TABLE IF EXISTS `Teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Teachers` (
  `teacher_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `employee_id` varchar(20) NOT NULL,
  `department` enum('sistemas','industrial','electronica','mecanica','civil','gestion','ciencias_basicas','administrativo','otro') NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `terms_accepted` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`teacher_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `employee_id` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Teachers`
--

LOCK TABLES `Teachers` WRITE;
/*!40000 ALTER TABLE `Teachers` DISABLE KEYS */;
INSERT INTO `Teachers` VALUES (1,'Roberto Carlos','Toledo Gomez','Prueba@itoaxaca.edu.mx','EMP001234','sistemas','$2b$12$3aP7PT189HV2W15lmZP6LO1w1FNF2ZgoIE4.yxVhKEqpbU8fQ3qAK',1,'2025-05-27 16:04:04');
/*!40000 ALTER TABLE `Teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `control_number` varchar(20) NOT NULL,
  `barcode_id` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `paternal_last_name` varchar(50) NOT NULL,
  `maternal_last_name` varchar(50) DEFAULT NULL,
  `group_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `control_number` (`control_number`),
  UNIQUE KEY `barcode_id` (`barcode_id`),
  KEY `group_id` (`group_id`),
  CONSTRAINT `Users_ibfk_1` FOREIGN KEY (`group_id`) REFERENCES `Grupos` (`group_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Users`
--

LOCK TABLES `Users` WRITE;
/*!40000 ALTER TABLE `Users` DISABLE KEYS */;
/*!40000 ALTER TABLE `Users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-29 13:33:33


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `course_enrollment_stats`;
/*!50001 DROP VIEW IF EXISTS `course_enrollment_stats`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `course_enrollment_stats` AS SELECT 
 1 AS `course_id`,
 1 AS `school_id`,
 1 AS `term_id`,
 1 AS `direct_enrollments`,
 1 AS `direct_credit_card`,
 1 AS `direct_license`,
 1 AS `term_enrollments`,
 1 AS `term_credit_card`,
 1 AS `term_license`,
 1 AS `students_enrolled`,
 1 AS `credit_card_enrollments`,
 1 AS `license_enrollments`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `term_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `content` varchar(255) DEFAULT NULL,
  `price` decimal(10,0) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_courses_on_term_id` (`term_id`),
  CONSTRAINT `fk_rails_2798fbd525` FOREIGN KEY (`term_id`) REFERENCES `terms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `purchase_id` bigint NOT NULL,
  `enrollable_type` varchar(255) NOT NULL,
  `enrollable_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_enrollments_on_student_id` (`student_id`),
  KEY `index_enrollments_on_purchase_id` (`purchase_id`),
  KEY `index_enrollments_on_enrollable` (`enrollable_type`,`enrollable_id`),
  KEY `index_enrollments_on_enrollable_type_and_enrollable_id` (`enrollable_type`,`enrollable_id`),
  KEY `idx_enrollments_access_check` (`student_id`,`enrollable_id`,`enrollable_type`),
  CONSTRAINT `fk_rails_9412741f5a` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`),
  CONSTRAINT `fk_rails_f01c555e06` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `licenses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licenses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `status` int DEFAULT NULL,
  `redeemed_at` datetime(6) DEFAULT NULL,
  `school_id` bigint NOT NULL,
  `term_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_licenses_on_code` (`code`),
  KEY `index_licenses_on_school_id` (`school_id`),
  KEY `index_licenses_on_term_id` (`term_id`),
  KEY `index_licenses_on_school_id_and_status` (`school_id`,`status`),
  CONSTRAINT `fk_rails_02b34f449f` FOREIGN KEY (`term_id`) REFERENCES `terms` (`id`),
  CONSTRAINT `fk_rails_e51847f457` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `method_type` int DEFAULT NULL,
  `details` json DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `license_id` bigint DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_payment_methods_on_student_id` (`student_id`),
  KEY `index_payment_methods_on_license_id` (`license_id`),
  KEY `index_payment_methods_on_method_type` (`method_type`),
  CONSTRAINT `fk_rails_2ea83dcf00` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  CONSTRAINT `fk_rails_597a968a54` FOREIGN KEY (`license_id`) REFERENCES `licenses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `platform_stats`;
/*!50001 DROP VIEW IF EXISTS `platform_stats`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `platform_stats` AS SELECT 
 1 AS `total_schools`,
 1 AS `total_students`,
 1 AS `total_courses`,
 1 AS `total_enrollments`,
 1 AS `credit_card_enrollments`,
 1 AS `license_enrollments`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `purchases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchases` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `active` tinyint(1) DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `payment_method_id` bigint NOT NULL,
  `purchaseable_type` varchar(255) NOT NULL,
  `purchaseable_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_purchases_on_student_id` (`student_id`),
  KEY `index_purchases_on_payment_method_id` (`payment_method_id`),
  KEY `index_purchases_on_purchaseable` (`purchaseable_type`,`purchaseable_id`),
  KEY `index_purchases_on_purchaseable_type_and_purchaseable_id` (`purchaseable_type`,`purchaseable_id`),
  KEY `index_purchases_on_active` (`active`),
  CONSTRAINT `fk_rails_e012d01423` FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`id`),
  CONSTRAINT `fk_rails_fec0590c68` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `school_stats`;
/*!50001 DROP VIEW IF EXISTS `school_stats`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `school_stats` AS SELECT 
 1 AS `school_id`,
 1 AS `students_count`,
 1 AS `terms_count`,
 1 AS `courses_count`,
 1 AS `active_enrollments`,
 1 AS `credit_card_enrollments`,
 1 AS `license_enrollments`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `schools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schools` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `admin_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_schools_on_admin_id` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `school_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_students_on_school_id` (`school_id`),
  KEY `index_students_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_0adebddbd5` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`),
  CONSTRAINT `fk_rails_148c9e88f4` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `term_stats`;
/*!50001 DROP VIEW IF EXISTS `term_stats`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `term_stats` AS SELECT 
 1 AS `term_id`,
 1 AS `school_id`,
 1 AS `courses_count`,
 1 AS `students_enrolled`,
 1 AS `credit_card_enrollments`,
 1 AS `license_enrollments`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `terms` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `school_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `price` decimal(10,0) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_terms_on_school_id` (`school_id`),
  CONSTRAINT `fk_rails_925a640cfe` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) NOT NULL DEFAULT '',
  `reset_password_token` varchar(255) DEFAULT NULL,
  `reset_password_sent_at` datetime(6) DEFAULT NULL,
  `remember_created_at` datetime(6) DEFAULT NULL,
  `role` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_reset_password_token` (`reset_password_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50001 DROP VIEW IF EXISTS `course_enrollment_stats`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`learning_platform`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `course_enrollment_stats` AS select `c`.`id` AS `course_id`,`t`.`school_id` AS `school_id`,`c`.`term_id` AS `term_id`,coalesce(`direct_stats`.`direct_enrollments`,0) AS `direct_enrollments`,coalesce(`direct_stats`.`direct_credit_card`,0) AS `direct_credit_card`,coalesce(`direct_stats`.`direct_license`,0) AS `direct_license`,coalesce(`term_stats`.`term_enrollments`,0) AS `term_enrollments`,coalesce(`term_stats`.`term_credit_card`,0) AS `term_credit_card`,coalesce(`term_stats`.`term_license`,0) AS `term_license`,(coalesce(`direct_stats`.`direct_enrollments`,0) + coalesce(`term_stats`.`term_enrollments`,0)) AS `students_enrolled`,(coalesce(`direct_stats`.`direct_credit_card`,0) + coalesce(`term_stats`.`term_credit_card`,0)) AS `credit_card_enrollments`,(coalesce(`direct_stats`.`direct_license`,0) + coalesce(`term_stats`.`term_license`,0)) AS `license_enrollments` from (((`courses` `c` join `terms` `t` on((`t`.`id` = `c`.`term_id`))) left join (select `c`.`id` AS `course_id`,count(distinct `e`.`id`) AS `direct_enrollments`,count(distinct (case when (`pm`.`method_type` = 0) then `e`.`id` end)) AS `direct_credit_card`,count(distinct (case when (`pm`.`method_type` = 1) then `e`.`id` end)) AS `direct_license` from ((((`courses` `c` left join `enrollments` `e` on(((`e`.`enrollable_type` = 'Course') and (`e`.`enrollable_id` = `c`.`id`)))) left join `students` `s` on((`s`.`id` = `e`.`student_id`))) left join `purchases` `p` on(((`p`.`id` = `e`.`purchase_id`) and (`p`.`active` = true)))) left join `payment_methods` `pm` on((`pm`.`id` = `p`.`payment_method_id`))) group by `c`.`id`) `direct_stats` on((`direct_stats`.`course_id` = `c`.`id`))) left join (select `c`.`id` AS `course_id`,count(distinct `e`.`id`) AS `term_enrollments`,count(distinct (case when (`pm`.`method_type` = 0) then `e`.`id` end)) AS `term_credit_card`,count(distinct (case when (`pm`.`method_type` = 1) then `e`.`id` end)) AS `term_license` from ((((`courses` `c` left join `enrollments` `e` on(((`e`.`enrollable_type` = 'Term') and (`e`.`enrollable_id` = `c`.`term_id`)))) left join `students` `s` on((`s`.`id` = `e`.`student_id`))) left join `purchases` `p` on(((`p`.`id` = `e`.`purchase_id`) and (`p`.`active` = true)))) left join `payment_methods` `pm` on((`pm`.`id` = `p`.`payment_method_id`))) group by `c`.`id`) `term_stats` on((`term_stats`.`course_id` = `c`.`id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `platform_stats`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`learning_platform`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `platform_stats` AS select (select count(0) from `schools`) AS `total_schools`,(select count(0) from `students`) AS `total_students`,(select count(0) from `courses`) AS `total_courses`,count(distinct `e`.`id`) AS `total_enrollments`,count(distinct (case when (`pm`.`method_type` = 0) then `e`.`id` end)) AS `credit_card_enrollments`,count(distinct (case when (`pm`.`method_type` = 1) then `e`.`id` end)) AS `license_enrollments` from (((`enrollments` `e` join `purchases` `p` on(((`p`.`id` = `e`.`purchase_id`) and (`p`.`active` = true)))) join `payment_methods` `pm` on((`pm`.`id` = `p`.`payment_method_id`))) join `students` `s` on((`s`.`id` = `e`.`student_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `school_stats`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`learning_platform`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `school_stats` AS select `s`.`id` AS `school_id`,count(distinct `st`.`id`) AS `students_count`,count(distinct `t`.`id`) AS `terms_count`,count(distinct `c`.`id`) AS `courses_count`,count(distinct `e`.`id`) AS `active_enrollments`,count(distinct (case when (`pm`.`method_type` = 0) then `e`.`id` end)) AS `credit_card_enrollments`,count(distinct (case when (`pm`.`method_type` = 1) then `e`.`id` end)) AS `license_enrollments` from ((((((`schools` `s` left join `students` `st` on((`st`.`school_id` = `s`.`id`))) left join `terms` `t` on((`t`.`school_id` = `s`.`id`))) left join `courses` `c` on((`c`.`term_id` = `t`.`id`))) left join `enrollments` `e` on((`e`.`student_id` = `st`.`id`))) left join `purchases` `p` on(((`p`.`id` = `e`.`purchase_id`) and (`p`.`active` = true)))) left join `payment_methods` `pm` on((`pm`.`id` = `p`.`payment_method_id`))) group by `s`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `term_stats`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`learning_platform`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `term_stats` AS select `t`.`id` AS `term_id`,`t`.`school_id` AS `school_id`,count(distinct `c`.`id`) AS `courses_count`,count(distinct `e`.`id`) AS `students_enrolled`,count(distinct (case when (`pm`.`method_type` = 0) then `e`.`id` end)) AS `credit_card_enrollments`,count(distinct (case when (`pm`.`method_type` = 1) then `e`.`id` end)) AS `license_enrollments` from (((((`terms` `t` left join `courses` `c` on((`c`.`term_id` = `t`.`id`))) left join `enrollments` `e` on(((`e`.`enrollable_type` = 'Term') and (`e`.`enrollable_id` = `t`.`id`)))) left join `students` `s` on(((`s`.`id` = `e`.`student_id`) and (`s`.`school_id` = `t`.`school_id`)))) left join `purchases` `p` on(((`p`.`id` = `e`.`purchase_id`) and (`p`.`active` = true)))) left join `payment_methods` `pm` on((`pm`.`id` = `p`.`payment_method_id`))) group by `t`.`id`,`t`.`school_id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('20250702084944'),
('20250701235232'),
('20250701235206'),
('20250627173453'),
('20250626193958'),
('20250625230628'),
('20250625222923'),
('20250625215545'),
('20250625215506'),
('20250625215425'),
('20250625214139'),
('20250625213719'),
('20250625213426'),
('20250625210331'),
('20250625210303'),
('20250625210112');


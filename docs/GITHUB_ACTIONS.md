# GitHub Actions CI Configuration

This project is configured to run continuous integration tests using GitHub Actions with MySQL.

## Configuration Details

### MySQL Service
- **Image**: mysql:8.0
- **Database**: learning_platform_test
- **User**: learning_platform
- **Password**: dummypassword
- **Port**: 3306

### Database Configuration
The `config/database.yml` is configured to automatically detect when running in GitHub Actions:
- **Local Development**: Uses MySQL socket connection (`/var/run/mysqld/mysqld.sock`)
- **GitHub Actions**: Uses TCP connection to `127.0.0.1:3306`

### Environment Variables
The following environment variables are set in the GitHub Actions workflow:
- `RAILS_ENV=test`
- `CI=true` (enables eager loading)
- `GITHUB_ACTIONS=true` (switches database connection mode)
- `DATABASE_URL=mysql2://learning_platform:dummypassword@127.0.0.1:3306/learning_platform_test`

### Workflow Steps
1. Install system packages including MySQL client
2. Set up Ruby with bundler cache
3. Wait for MySQL service to be ready
4. Prepare test database and run tests
5. Upload screenshots from failed system tests (if any)

## Running Tests Locally
To run tests locally, ensure you have MySQL running and the database configured as specified in `database.yml`.

## Troubleshooting
- If tests fail with database connection errors, check that the MySQL service is healthy
- The workflow includes a health check that waits for MySQL to be ready
- Database credentials must match between the service configuration and `database.yml`

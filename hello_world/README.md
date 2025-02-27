# **Quarkus Serverless Workflow - Setup Guide**

This guide documents **every step** required to set up and run a **Quarkus Serverless Workflow** with PostgreSQL. It includes installation, configuration, troubleshooting, and verification steps.

---

## **1. Prerequisites**
Before starting, ensure you have the following installed:

- **Java 17+** (`brew install openjdk@17`)
- **Maven** (`brew install maven`)
- **Quarkus CLI** (optional: `brew install quarkus`)
- **PostgreSQL** (using **Homebrew** or **Podman**)
- **Podman or Docker** (if using a containerized database)

---

## **2. Clone the Repository**
Navigate to your working directory and clone the project:

```sh
git clone <your-repo-url>
cd hello_world
```

---

## **3. Start PostgreSQL**
Choose **one** of the following methods:

### **Option 1: Using Homebrew (Local Installation)**
```sh
brew install postgresql@14
brew services start postgresql
```

Create the `quarkusdb` database and user:
```sh
psql postgres
```

Then, run:
```sql
CREATE DATABASE quarkusdb;
CREATE USER quarkus WITH ENCRYPTED PASSWORD 'quarkus';
GRANT ALL PRIVILEGES ON DATABASE quarkusdb TO quarkus;
```

Exit PostgreSQL:
```sh
\q
```

### **Option 2: Using Podman/Docker**
Run PostgreSQL in a container:

```sh
podman run --name postgres \
    -e POSTGRES_USER=quarkus \
    -e POSTGRES_PASSWORD=quarkus \
    -e POSTGRES_DB=quarkusdb \
    -p 5432:5432 -d docker.io/postgres:14
```

Verify it's running:
```sh
podman ps
```

---

## **4. Verify Database Connection**
Run:

```sh
psql -h localhost -U quarkus -d quarkusdb -c "\dt"
```

If no tables are found, proceed to **Step 5**.

---

## **5. Manually Create the Required Table**
By default, Quarkus **may not create** the necessary `process_instances` table.

### **Check if Table Exists**
```sh
psql -h localhost -U quarkus -d quarkusdb -c "\dt"
```

If `process_instances` is missing, create it manually:

```sh
psql -h localhost -U quarkus -d quarkusdb
```

Run the following SQL:
```sql
CREATE TABLE IF NOT EXISTS process_instances (
    id UUID PRIMARY KEY,
    process_id VARCHAR(255) NOT NULL,
    state INT NOT NULL,
    variables JSONB,
    start_date TIMESTAMP DEFAULT now(),
    end_date TIMESTAMP
);
```

Exit:
```sh
\q
```

Verify again:
```sh
psql -h localhost -U quarkus -d quarkusdb -c "\dt"
```

---

## **6. Configure Quarkus**
Modify `application.properties`:

```properties
# Standard JDBC datasource
%dev.quarkus.datasource.db-kind=postgresql
%dev.quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.username=quarkus
%dev.quarkus.datasource.password=quarkus

# Reactive PostgreSQL Configuration
%dev.quarkus.datasource.reactive.url=postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.reactive.username=quarkus
%dev.quarkus.datasource.reactive.password=quarkus

# Hibernate ORM Configuration
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
%dev.quarkus.hibernate-orm.sql-load-script=no-file
```

---

## **7. Start Quarkus Application**
Run the application in **dev mode**:

```sh
mvn quarkus:dev -Dquarkus.hibernate-orm.log.sql=true
```

If successful, you should see logs indicating **Quarkus has started**.

---

## **8. Verify the Application**
### **8.1 Check Dev UI**
Open:
```
http://localhost:8080/q/dev-ui
```

### **8.2 Check Swagger UI**
```
http://localhost:8080/q/swagger-ui
```

### **8.3 Test Workflow with API Request**
Send a request using `curl`:

```sh
curl -X POST "http://localhost:8080/hello" -H "Content-Type: application/json" -d '{}'
```

### **8.4 Expected Response**
```json
{
  "message": "Hello World"
}
```

---

## **9. Automating Table Creation (Optional)**
To **automatically create the table** if it does not exist, you can use the following SQL script:

```sql
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'process_instances') THEN
        CREATE TABLE process_instances (
            id UUID PRIMARY KEY,
            process_id VARCHAR(255) NOT NULL,
            state INT NOT NULL,
            variables JSONB,
            start_date TIMESTAMP DEFAULT now(),
            end_date TIMESTAMP
        );
    END IF;
END $$;
```

You can integrate this into a **Flyway migration script** or execute it at startup.

---

## **10. Troubleshooting**
### **Issue: `relation "process_instances" does not exist`**
- Run:
  ```sh
  psql -h localhost -U quarkus -d quarkusdb -c "\dt"
  ```
- If missing, create manually (**Step 5**).

### **Issue: Unable to Connect to PostgreSQL**
For **Homebrew PostgreSQL**, restart the service:

```sh
brew services restart postgresql
```

For **Podman/Docker PostgreSQL**, check logs:

```sh
podman logs postgres
```

### **Issue: Unrecognized Configuration Keys in Logs**
Warnings like:
```
Unrecognized configuration key "quarkus.datasource.reactive.username"
```
These can be ignored, but double-check your `application.properties`.

---

## **11. Next Steps**
- Modify the workflow to add additional logic.
- Integrate with Kafka, REST endpoints, or event-driven services.
- Deploy the workflow to OpenShift or Kubernetes.

---


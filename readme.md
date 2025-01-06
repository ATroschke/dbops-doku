# README: Vergleich und Anleitung zu Flyway und Bytebase

## 1. Einleitung
In einem Unternehmen mit etwa 10 Softwareentwicklern, die gemeinsam an mehreren Projekten arbeiten, sind konsistente und effiziente Datenbankänderungen von entscheidender Bedeutung. Systeme wie Flyway und Bytebase bieten eine strukturierte Methode, um Datenbankmigrationen zu verwalten, und lösen typische Probleme wie:

- **Kollaborationsprobleme:** Änderungen von verschiedenen Entwicklern führen oft zu Konflikten.
- **Nachvollziehbarkeit:** Wer hat welche Änderungen vorgenommen?
- **Automatisierung:** Manuelle Migrationen sind zeitaufwendig und fehleranfällig.
- **Revisionssicherheit:** Änderungen können leicht zurückverfolgt und notfalls rückgängig gemacht werden.

Diese Tools bieten außerdem eine bessere Integration in CI/CD-Pipelines, was die Bereitstellung und Wartung vereinfacht.

---

## 2. Flyway

### Funktionsweise
Flyway ist ein migrationsbasiertes Datenbankverwaltungssystem, das Änderungen anhand nummerierter SQL- oder Java-Dateien verwaltet. Migrationen werden sequenziell und versionsbasiert durchgeführt. Flyway überprüft die Konsistenz und verhindert Probleme wie das Überschreiben von Änderungen.

- **Migrationen:** SQL-Dateien (z. B. `V1__init.sql`) enthalten die Anweisungen für Änderungen.
- **Schema-Verlauf:** Flyway speichert den Verlauf in einer speziellen Schema-Tabelle.
- **Integrationsmöglichkeiten:** Flyway ist leicht in CI/CD-Pipelines einzubinden.

### Beispiel: Flyway in GitLab Self-hosted einbinden

1. **Voraussetzungen:**
    - GitLab Runner ist eingerichtet.
    - Docker ist auf dem Runner verfügbar.
    - `flyway`-Image wird verwendet.

2. **Projektstruktur:**
    ```plaintext
    project-root/
    ├── .gitlab-ci.yml
    ├── migrations/
    │   ├── V1__init.sql
    │   ├── V2__add_users_table.sql
    │   └── ...
    └── docker-compose.flyway.yml
    ```

3. **GitLab CI/CD Pipeline:**
    ```yaml
    stages:
      - validate
      - migrate

    validate:
      stage: validate
      script:
        - docker run --rm -v $CI_PROJECT_DIR/migrations:/flyway/sql flyway/flyway:latest -url=jdbc:mysql://mariadb:3306/db -user=root -password=root validate

    migrate:
      stage: migrate
      script:
        - docker run --rm -v $CI_PROJECT_DIR/migrations:/flyway/sql flyway/flyway:latest -url=jdbc:mysql://mariadb:3306/db -user=root -password=root migrate
    ```

    Wichtig: Verbindungsdaten (URL, Benutzername, Passwort) sollten als Secrets in GitLab hinterlegt werden.

4. **Migration hinzufügen:**
    - Erstelle eine neue SQL-Datei im `migrations/`-Verzeichnis (z. B. `V3__add_new_column.sql`).
    - Committe die Änderungen und pushe sie. Die Pipeline führt automatisch die neuen Migrationen aus.

### Flyway: Integration in GitLab PR/Branch-Workflow

#### Branch-Setup für DEV und PROD
1. **Branching-Strategie:**
    - Verwenden Sie zwei Hauptbranches:
        - `main`: Für die Produktionsumgebung (PROD).
        - `staging`: Für die Entwicklungsumgebung (DEV).
    - Änderungen sollten über Feature-Branches entwickelt werden und über Pull Requests (PRs) in `staging` gemergt werden.
    - Nach erfolgreichen Tests in `staging` können Änderungen in `main` gemergt werden.

#### CI/CD-Workflow mit Flyway

##### Pipeline-Erweiterung für PR-Validierung
Fügen Sie in Ihrer `.gitlab-ci.yml` einen Job hinzu, der sicherstellt, dass alle Migrationen valide sind, bevor ein Merge erfolgt:
```yaml
validate:
  stage: validate
  script:
    - docker run --rm -v $CI_PROJECT_DIR/migrations:/flyway/sql flyway/flyway:latest -url=jdbc:mysql://mariadb:3306/db -user=root -password=root validate
  only:
    - merge_requests
```

##### Migration basierend auf Branch
Richten Sie den Migrationsprozess so ein, dass er die richtige Datenbank basierend auf dem Branch aktualisiert:
```yaml
migrate:
  stage: migrate
  script:
    - >
      docker run --rm -v $CI_PROJECT_DIR/migrations:/flyway/sql
      flyway/flyway:latest
      -url=${CI_DB_URL}
      -user=${CI_DB_USER}
      -password=${CI_DB_PASSWORD}
      migrate
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        CI_DB_URL: "jdbc:mysql://prod-db:3306/prod_db"
    - if: $CI_COMMIT_BRANCH == "staging"
      variables:
        CI_DB_URL: "jdbc:mysql://dev-db:3306/dev_db"
```

##### Rollback-Strategie
Rollback-Skripte erstellen:
- Für jede Migration ein Rollback-Skript anlegen (z. B. `U1__rollback_init.sql`).
- Rollbacks sollten die Änderungen rückgängig machen, z. B. Tabellen löschen oder Spalten entfernen.

Rollback-Pipeline hinzufügen:
```yaml
rollback:
  stage: rollback
  script:
    - >
      docker run --rm -v $CI_PROJECT_DIR/migrations:/flyway/sql
      flyway/flyway:latest
      -url=${CI_DB_URL}
      -user=${CI_DB_USER}
      -password=${CI_DB_PASSWORD}
      undo
  manual: true
```

---

## 3. Bytebase

### Funktionsweise
Bytebase ist eine webbasierte Plattform für die Verwaltung von Datenbankänderungen. Im Vergleich zu Flyway bietet Bytebase eine Benutzeroberfläche, über die Migrationen geplant, genehmigt und überwacht werden können. Bytebase eignet sich besonders für größere Teams mit komplexen Workflows.

- **Migrationen:** SQL-Skripte werden hochgeladen und in der UI verwaltet.
- **Genehmigungs-Workflows:** Änderungen können von mehreren Parteien geprüft werden.
- **Historie:** Alle Änderungen sind nachvollziehbar.

### Beispiel: Bytebase in GitLab Self-hosted einbinden

1. **Bytebase starten:**
    - Verwende die `start-bytebase.(bat/sh)`, um Bytebase zu starten.
    - Öffne Bytebase unter `http://localhost:8080`.

2. **Projekt einrichten:**
    - Melde dich bei Bytebase an und erstelle ein neues Projekt.
    - Verbinde die MariaDB-Instanz.

3. **CI/CD-Integration:**
    - Füge ein neues Git-Repository in Bytebase hinzu.
    - Definiere Migrationen als SQL-Dateien in einem dedizierten Ordner (z. B. `db-migrations/`).

4. **GitLab CI/CD Pipeline:**
    ```yaml
    stages:
      - plan
      - apply

    plan:
      stage: plan
      script:
        - curl -X POST -H "Authorization: Bearer $BYTEBASE_API_KEY" \
          -d '{"project":"example","file":"migration.sql"}' \
          http://bytebase:8080/api/plan

    apply:
      stage: apply
      script:
        - curl -X POST -H "Authorization: Bearer $BYTEBASE_API_KEY" \
          http://bytebase:8080/api/apply
    ```

5. **Migration hinzufügen:**
    - Lade ein neues SQL-Skript in den definierten Migrations-Ordner hoch.
    - Plane die Änderung in Bytebase und führe sie durch.

### Bytebase: Erweiterte Einrichtung

#### Einrichtung einer Bytebase-Instanz
Bytebase installieren:
- Installieren und starten Sie Bytebase mit Docker:
    ```bash
    docker run -d --name bytebase -p 8080:8080 bytebase/bytebase
    ```
- Öffnen Sie die Weboberfläche unter [http://localhost:8080](http://localhost:8080) und erstellen Sie ein Admin-Konto.

#### Projekt und Datenbank hinzufügen:
- Erstellen Sie in der Bytebase-UI ein neues Projekt.
- Fügen Sie Datenbanken (z. B. DEV und PROD) hinzu:
    - Gehen Sie zu "Datenbank hinzufügen".
    - Geben Sie Host, Port, Benutzername und Passwort ein.
    - Ordnen Sie jede Datenbank der entsprechenden Umgebung (DEV/PROD) zu.

#### Benutzer und Berechtigungen
Rollen und Rechte definieren:
- Gehen Sie zu Einstellungen > Benutzerverwaltung.
- Erstellen Sie Rollen wie:
    - Entwickler: Kann Migrationen erstellen.
    - Reviewer: Kann Migrationen überprüfen.
    - Admin: Kann alle Aktionen ausführen.

#### Genehmigungsprozesse aktivieren:
- Konfigurieren Sie für die PROD-Umgebung Genehmigungsworkflows:
    - Gehen Sie zu Einstellungen > Workflow.
    - Legen Sie fest, dass Migrationen in PROD mindestens eine Genehmigung benötigen.

#### Rollback-Strategie
Rollback-Skripte erstellen und hochladen:
- Erstellen Sie ein separates SQL-Skript für den Rollback.
- Fügen Sie es in Bytebase als neue Revision hinzu.

Rollback ausführen:
- Gehen Sie in der Bytebase-UI zur betroffenen Revision.
- Klicken Sie auf "Rollback ausführen" und bestätigen Sie die Änderungen.

---

## 4. Pro- und Kontra

### Flyway
- **Vorteile:**
    - Einfache Einrichtung und Nutzung.
    - Perfekt für Entwickler, die mit Skripten arbeiten.
    - Integration in CI/CD ist straightforward.
- **Nachteile:**
    - Keine Benutzeroberfläche für komplexe Workflows.
    - Genehmigungsprozesse müssen extern organisiert werden.

### Bytebase
- **Vorteile:**
    - Benutzerfreundliche Oberfläche.
    - Ideal für größere Teams mit Genehmigungsprozessen.
    - Historie und Auditing sind integriert.
- **Nachteile:**
    - Höherer Initialaufwand bei der Einrichtung.
    - Weniger geeignet für rein skriptbasierte Workflows.

### Vergleich mit manuellen Migrationen
- **Manuelle Migrationen:**
    - **Pro:** Vollständige Kontrolle.
    - **Kontra:** Fehleranfällig, zeitaufwendig, keine Konsistenzprüfung.
- **Automatisierte Systeme:**
    - **Pro:** Konsistent, skalierbar, auditierbar.
    - **Kontra:** Höherer Initialaufwand.
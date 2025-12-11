from sqlalchemy import create_engine, inspect
from app.db.database import DATABASE_URL


def inspect_db():
    engine = create_engine(DATABASE_URL)
    inspector = inspect(engine)

    tables = inspector.get_table_names()
    print(f"Tables found: {tables}")

    target_tables = ["TB_MENOPAUSE_SURVEY_RESULT", "TB_MENOPAUSE_SURVEY_ANSWER"]

    for table in target_tables:
        if (
            table in tables or table.lower() in tables
        ):  # Case insensitivity check might vary
            # Find exact name matches
            actual_name = table if table in tables else table.lower()
            if (
                actual_name not in tables
            ):  # if still not found, try case insensitive search
                matches = [t for t in tables if t.lower() == table.lower()]
                if matches:
                    actual_name = matches[0]
                else:
                    print(f"Table {table} NOT found.")
                    continue

            print(f"--- Columns in {actual_name} ---")
            columns = inspector.get_columns(actual_name)
            for col in columns:
                print(f"  {col['name']} ({col['type']})")
        else:
            print(f"Table {table} NOT found.")


if __name__ == "__main__":
    inspect_db()

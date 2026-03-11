import json
from typing import List, Dict, Any
from pathlib import Path

import jsonref
import yaml
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader
from jinja2 import Template

JSONSCHEMA_TEMPLATE_NAME = "values.schema.tmpl.json"
JSONSCHEMA_NAME = "values.schema.json"
VALUES_FILE = "values.yaml"
CHART_YAML = "Chart.yaml"

def read_yaml(file_path: Path):
    """Open and load Chart.yaml file."""
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.load(f, Loader=Loader)

def template_schema(chart_dir: Path, my_chart_yaml: Dict[str, Any]):
    """Load values.schema.tmpl.json and template it via Jinja2.

    Returns None if the template file does not exist.
    """
    template_path = chart_dir / JSONSCHEMA_TEMPLATE_NAME
    if not template_path.exists():
        print(f"INFO: '{template_path}' not found; '{JSONSCHEMA_NAME}' will not be created or updated for '{chart_dir}'")
        return None

    with open(template_path, "r", encoding="utf-8") as f:
        my_schema_template = Template(f.read(), autoescape=True)

    return json.loads(my_schema_template.render(my_chart_yaml))

def tidy_schema(my_schema: Any, my_values: Any):
    """Hack to support OCP Form view.

    https://issues.redhat.com/browse/OCPBUGS-14874
    https://issues.redhat.com/browse/OCPBUGS-14875
    """
    if isinstance(my_schema, dict):
        my_schema.pop("$schema", None)
        my_schema.pop("format", None)

        # Override existing defaults so OCP form view
        # doesn't try to override our defaults
        if my_schema.get("default") is not None and my_values is not None:
            my_schema["default"] = my_values

        # Tidy up properties for type: object
        properties: Dict[str, Any] = my_schema.get("properties", {})
        for k, v in properties.items():
            if isinstance(my_values, dict):
                new_values = my_values.get(k, None)
            else:
                new_values = None
            tidy_schema(v, new_values)

        # Tidy up properties for type: array
        items: Dict[str, Any] = my_schema.get("items", {})
        if items:
            tidy_schema(items, my_values)
    return my_schema

def save(chart_dir: Path, my_schema: Any):
    """Take schema containing $refs and dereference them."""
    with open(chart_dir / JSONSCHEMA_NAME, "w", encoding="utf-8") as f:
        json.dump(my_schema, f, indent=4, sort_keys=True)

if __name__ == '__main__':
    charts = [p.parent for p in Path(".").rglob(CHART_YAML)]

    errors: List[BaseException] = []
    for chart in charts:
        try:
            chart_yaml = read_yaml(chart / CHART_YAML)
            values = read_yaml(chart / VALUES_FILE)
            schema_template = template_schema(chart, chart_yaml)
            if schema_template is None:
                continue
            schema = jsonref.replace_refs(schema_template)
            schema = tidy_schema(schema, values)

            save(chart, schema)
        except BaseException as e:
            print(f"Could not process schema for '{chart}': {e}")
            errors.append(e)
    if errors:
        exit(1)

# test_app.py — Unit tests for our API
# pytest runs these automatically in the pipeline
# If ANY test fails → pipeline stops → code does NOT get deployed
# This protects production from broken code

import pytest
from app import app


# Create a test client — simulates HTTP requests without starting a real server
@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_check(client):
    """Health endpoint should return 200 and status healthy"""
    response = client.get('/health')
    data = response.get_json()

    assert response.status_code == 200
    assert data['status'] == 'healthy'
    assert data['version'] == '1.0.0'


def test_get_notes_empty(client):
    """Notes list should be empty at start"""
    response = client.get('/notes')
    data = response.get_json()

    assert response.status_code == 200
    assert data['notes'] == []
    assert data['total'] == 0


def test_create_note(client):
    """Creating a note should return 201 and the note data"""
    response = client.post('/notes',
        json={"title": "Test note", "content": "Testing pipeline"},
        content_type='application/json'
    )
    data = response.get_json()

    assert response.status_code == 201
    assert data['title'] == 'Test note'
    assert data['content'] == 'Testing pipeline'
    assert 'id' in data
    assert 'created_at' in data


def test_create_note_missing_title(client):
    """Creating a note without title should return 400 error"""
    response = client.post('/notes',
        json={"content": "No title here"},
        content_type='application/json'
    )
    data = response.get_json()

    assert response.status_code == 400
    assert 'error' in data

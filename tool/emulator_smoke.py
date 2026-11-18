#!/usr/bin/env python3
"""Disposable users and records against fixed local emulators only; no real emails."""
import json
import time
import urllib.error
import urllib.request

AUTH = 'http://127.0.0.1:9198/identitytoolkit.googleapis.com/v1/accounts:'
DB = 'http://127.0.0.1:8188/v1/projects/demo-trampo/databases/(default)/documents/'


def request(url, method='GET', data=None, token=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(url, data=None if data is None else json.dumps(data).encode(), headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            status, body = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, body = error.code, error.read()
    assert status == expected, f'{method} expected {expected}, received {status}: {body[:300]!r}'
    return json.loads(body) if body else None


def value(item):
    if item is None:
        return {'nullValue': None}
    if isinstance(item, bool):
        return {'booleanValue': item}
    if isinstance(item, int):
        return {'integerValue': str(item)}
    if isinstance(item, str):
        return {'stringValue': item}
    if isinstance(item, list):
        return {'arrayValue': {'values': [value(x) for x in item]}}
    if isinstance(item, dict):
        return {'mapValue': {'fields': {k: value(v) for k, v in item.items()}}}
    raise ValueError('Unsupported test value')


def main():
    suffix = str(time.time_ns())
    email = 'trampo-' + suffix + '@example.invalid'
    password = 'synthetic-password-123'
    signup = lambda mail: request(AUTH + 'signUp?key=demo-api-key', 'POST', {'email': mail, 'password': password, 'returnSecureToken': True})
    owner = signup(email)
    other = signup('other-' + email)
    path = DB + 'users/' + owner['localId'] + '/workspace/current'
    payload = {'version': 1, 'language': 'pt', 'clients': [{'id': 'c', 'name': 'Synthetic client', 'phone': '', 'notes': ''}], 'jobs': [{'id': 'j', 'clientId': 'c', 'title': 'Synthetic repair', 'notes': '', 'status': 'quote', 'start': None, 'end': None, 'budget': {'labor': 10010, 'materials': 20020, 'discount': 30}, 'history': [{'at': '2026-11-17T15:00:00.000Z', 'status': 'quote', 'action': 'created', 'title': 'Synthetic repair', 'total': 30000, 'clientId': 'c'}]}]}
    fields = lambda revision: {k: value(v) for k, v in {'revision': revision, 'payload': payload}.items()}
    request(path, 'PATCH', {'fields': fields(1)}, owner['idToken'])
    restored = request(path, token=owner['idToken'])
    assert restored['fields']['payload']['mapValue']['fields']['language']['stringValue'] == 'pt'
    jobs = restored['fields']['payload']['mapValue']['fields']['jobs']['arrayValue']['values']
    assert jobs[0]['mapValue']['fields']['budget']['mapValue']['fields']['labor']['integerValue'] == '10010'
    request(path, expected=403)
    request(path, token=other['idToken'], expected=403)
    request(path, 'PATCH', {'fields': fields(2)}, other['idToken'], expected=403)
    request(path, 'PATCH', {'fields': fields(99)}, owner['idToken'], expected=403)
    payload['language'] = 'en'
    request(path, 'PATCH', {'fields': fields(2)}, owner['idToken'])
    request(path, 'PATCH', {'fields': fields(2)}, owner['idToken'], expected=403)
    request(path, 'DELETE', token=owner['idToken'], expected=403)
    signed_in = request(AUTH + 'signInWithPassword?key=demo-api-key', 'POST', {'email': email, 'password': password, 'returnSecureToken': True})
    assert signed_in['localId'] == owner['localId']
    request(AUTH + 'signInWithPassword?key=demo-api-key', 'POST', {'email': email, 'password': 'incorrect', 'returnSecureToken': True}, expected=400)
    print('PASS: synthetic auth, persisted snapshot, unauthenticated rejection, owner isolation, monotonic revisions, stale writes, denied deletion, sign-in and invalid password.')


if __name__ == '__main__':
    main()

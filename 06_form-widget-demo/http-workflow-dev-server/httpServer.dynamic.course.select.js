/*
 * Copyright Red Hat, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const express = require('express');

const app = express();
app.disable('x-powered-by');

const port = 12345;
app.use(express.json());

const logRequest = req => {
  // eslint-disable-next-line no-console
  console.log('request: ', {
    originalUrl: req.originalUrl,
    method: req.method,
    query: req.query,
    headers: req.headers,
    body: req.body,
  });
};

const UNDEFINED = '___undefined___';

app.get('/', (_, res) => {
  res.send(
    'Hello World from HTTP test server providing endpoints for the "Dynamic course select" workflow',
  );
});

app.post('/courses', (req, res) => {
  logRequest(req);

  const requesterName = req.body?.requesterName;
  const studentName = req.query?.studentname;

  let joinedRequesterName = requesterName;
  if (Array.isArray(requesterName)) {
    joinedRequesterName = requesterName.join(' ');
  }

  const optionsForAutocomplete = [
    'one course',
    'another course',
    'complexCourse',
    `a course just for ${joinedRequesterName}`,
  ];
  if (studentName && studentName !== UNDEFINED) {
    optionsForAutocomplete.push(`I want to be a course for ${studentName}`);
  }

  const result = {
    // Use whatever structure here, just make sure the selectors in the data input schema picks correct values and types
    mycourses: { mydefault: optionsForAutocomplete[0] },
    listofcourses: { all: optionsForAutocomplete },
  };

  // HTTP 200
  res.send(JSON.stringify(result));
});

app.get('/coursedetailsschema', (req, res) => {
  logRequest(req);

  const courseName = req.query?.coursename;
  if (!courseName || courseName === UNDEFINED) {
    // Not enough data yet
    res.send(
      JSON.stringify({
        /* replace nothing */
      }),
    );
    return;
  }

  const uiOrder = ['nickname', 'room'];

  const fields = {
    room: {
      type: 'string',
      title:
        'Room (example of ActiveTextInput supplied by SchemaUpdater, validation)',
      'ui:widget': 'ActiveTextInput',
      'ui:props': {
        devonlycomment:
          'Fetches default value, validates externally the data but does not have autocomplete.',
        'fetch:url':
          '$${{backend.baseUrl}}/api/proxy/mytesthttpserver/rooms?coursename=$${{current.courseName}}',
        'fetch:response:value': 'room.mydefault',
        'fetch:retrigger': ['current.courseName'],
        'fetch:method': 'GET',
        'validate:url':
          '$${{backend.baseUrl}}/api/proxy/mytesthttpserver/validateroom',
        'validate:method': 'POST',
        'validate:body': {
          field: 'courseDetails.room',
          value: '$${{current.courseDetails.room}}',
          courseName: '$${{current.courseName}}',
        },
      },
    },
    nickname: {
      type: 'string',
      title: 'Your nickname',
    },
  };

  if (courseName === 'complexCourse') {
    fields.requestCertificate = {
      type: 'boolean',
      title: 'Receive a certificate',
      'ui:widget': 'radio',
    };
    uiOrder.push('requestCertificate');
  }

  const courseDetailsSchema = {
    // The 'courseDetails' name matches the placeholder in the data input schema
    courseDetails: {
      type: 'object',
      title: `Course details for "${courseName}"`,
      properties: fields,
      'ui:order': uiOrder,
    },
  };

  // HTTP 200
  res.send(JSON.stringify(courseDetailsSchema));
});

app.post('/certificatesschema', (req, res) => {
  logRequest(req);

  // example of passing template arrays
  const courseNames = req.body?.courseNames;

  if (!Array.isArray(courseNames) || courseNames.length < 1) {
    return {};
  }

  // A complex data object with redundant props.
  // The "fetch:response:value" selector needs to be used to pick-up the relevant content for the SchemaUpdater widget.
  // In particular, it will match the "complexResponse.mydataroot.mydata" which is an object containing a single property "sendCertificatesAs" which matches a property in the UI schema
  const complexResponse = {
    "foo": "bar",
    "prop1": {
      "subprop": "a lot of complex but useless stuff"
    },
    "mydataroot": {}
  };

  let content;
  if (courseNames[0] === 'one course') {
    content = {
      sendCertificatesAs: {
        type: 'string',
        title: 'Send certificates via',
        "enum": [
          "email",
          "post",
          "pigeon"
        ]
      },
    };
  } else {
    content = {
      sendCertificatesAs: {
        type: 'string',
        title: 'Send certificates via',
        "ui:widget": "ActiveText",
        "ui:props": {
          "ui:variant": "caption",
          "ui:text": "This course does not provide any certificate."
        }
      },
    };
  }
  complexResponse.mydataroot.mydata = content;

  // HTTP 200
  res.send(JSON.stringify(complexResponse));
});
app.get('/rooms', (req, res) => {
  logRequest(req);

  // const courseName = req.query?.coursename;

  const result = {
    room: { mydefault: 'Dynamically fetched default room name' },
  };

  // HTTP 200
  res.send(JSON.stringify(result));
});

app.post('/validateroom', (req, res) => {
  logRequest(req);

  const field = req.body?.field;
  const value = req.body?.value;
  const courseName = req.body?.courseName;

  if (field === 'courseDetails.room') {
    if (!value || value.length < 5) {
      // any 4xx or 5xx is fine here
      res.status(422);
      res.send({
        [field]: [
          'The field must be 5 or more characters long.',
          `This is something specific for ${courseName} courseName.`,
        ],
      });

      return;
    }
  }

  // The HTTP 200 is important here. The response content "Valid" is not required, just a courtesy.
  res.status(200);
  res.send('Valid');
});

app.get('/preferred-teacher', (req, res) => {
  logRequest(req);

  const studentName = req.query?.studentname;
  const courseName = req.query?.coursename;

  const labels = [
    'Tim',
    'Jack ',
    'John',
    `Special teacher for "${courseName}"`,
  ];

  const values = ['123_tim', '456_jack', '789_john', 'he_is_special'];

  if (studentName && studentName !== UNDEFINED) {
    labels.push(`Someone who knows ${studentName}`);
    values.push('acquaintant');
  }

  const result = {
    // Use whatever structure here, just make sure the selectors in the data input schema picks correct values and labels.
    // For example, it means fetch:response:label and fetch:response:value in case of the ActiveDropdown.
    foo: {},
    bar: { labels },
    values,
  };

  // HTTP 200
  res.send(JSON.stringify(result));
});

app.post('/validateteacher', (req, res) => {
  logRequest(req);

  const field = req.body?.field;
  const value = req.body?.value;
  const courseName = req.body?.courseName;
  // const studentName = req.body?.studentName;

  if (field === 'preferredTeacher') {
    if (value === '789_john') {
      // any 4xx or 5xx is fine here
      res.status(422);
      res.send({
        [field]: ['Unfortunately John became already unavailable.'],
      });

      return;
    }

    if (value === '456_jack' && courseName === 'one course') {
      res.status(422);
      res.send({
        [field]: [`Jack newly prefers other topics than "${courseName}".`],
      });

      return;
    }
  }

  // The HTTP 200 is important here. The response content "Valid" is not required, just a courtesy.
  res.status(200);
  res.send('Valid');
});

app.get('/coursedetailsschema', (req, res) => {
  logRequest(req);

  const courseName = req.query?.coursename;

  let mydefault = 'My default room';
  if (courseName && courseName !== UNDEFINED) {
    mydefault += ` for "${courseName}" course`;
  }

  const response = {
    // The structure matches the "fetch:response:value" selector from "/coursedetailsschema" endpoint
    room: {
      mydefault,
    },
  };

  // HTTP 200
  res.send(JSON.stringify(response));
});

app.get('/suggested-courses', (req, res) => {
  logRequest(req);

  const courseName = req.query?.coursename;

  let suggestions = [];
  if (courseName === 'one course') {
    suggestions = ['Related Course A', 'Another Related Course'];
  } else if (courseName === 'another course') {
    suggestions = ['One More Course', 'And Another One'];
  } else if (courseName === 'complexCourse') {
    suggestions = ['Advanced Topics', 'Master Class'];
  } else {
    suggestions = ['Consider these too!', 'Explore other options'];
  }

  const response = {
    suggestions: suggestions.join(', '),
  };

  // HTTP 200
  res.send(JSON.stringify(response));
});

app.get('/drinks', (req, res) => {
  logRequest(req);

  const response = {
    myWarehouse: {
      food: {},
      drinks: [
        {"name": "water", "price": 10},
        {"name": "sparkling water", "price": 15},
        {"name": "water with lemon", "price": 20},
        {"name": "water on rocks", "price": 25},
        {"name": "prohibited drink", "price": 30},
      ]
    },
  }

  // HTTP 200
  res.send(
    JSON.stringify(response),
  );
});

app.get('/mascots', (req, res) => {
  logRequest(req);

  const studentName = req.query?.studentname;

  const allMascots = [
    'penguin',
    'pikachu',
    'dragon',
    'dog',
    'cat'
  ];

  if (studentName && studentName !== UNDEFINED) {
    allMascots.push(`a pet of ${studentName}`);
  }

  const response = {
    allMascots,
  }

  // HTTP 200
  res.send(
    JSON.stringify(response),
  );
});

app.post('/validatedrinks', (req, res) => {
  logRequest(req);

  const field = req.body?.field;
  const value = req.body?.value;

  if (field === 'complimentaryDrinks') {
    if (!Array.isArray(value)) {
      // any 4xx or 5xx is fine here
      res.status(422);
      res.send({
        [field]: ['Unexpected validation error - list of drinks is expected'],
      });

      return;
    }

    if (value.includes('prohibited drink')) {
      // any 4xx or 5xx is fine here
      res.status(422);
      res.send({
        [field]: ['You can not have the prohibited drink, try something else'],
      });

      return;
    }
  }

  // The HTTP 200 is important here. The response content "Valid" is not required, just a courtesy.
  res.status(200);
  res.send('Valid');
});
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.info(
    `Simple HTTP server for orchestrator-form-widgets development only. Provides endpoints for the "Dynamic course select" example workflow. Listening on ${port} port.`,
  );
});

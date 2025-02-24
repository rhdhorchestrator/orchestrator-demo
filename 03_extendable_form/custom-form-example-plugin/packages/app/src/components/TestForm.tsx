/* eslint-disable no-console */

import React from 'react';
import { Header, Page, Content } from '@backstage/core-components';
import { OrchestratorForm } from '@red-hat-developer-hub/backstage-plugin-orchestrator-form-react';
import { JsonObject } from '@backstage/types';
import { JSONSchema7 } from 'json-schema';

const schema = {
  type: 'object',
  properties: {
    personalInfo: {
      type: 'object',
      title: 'Personal Information',
      properties: {
        firstName: { type: 'string', title: 'First Name', default: 'John' },
        lastName: { type: 'string', title: 'Last Name' },
        country: {
          type: 'string',
          title: 'Country',
          'ui:widget': 'CountryWidget',
        },
        password: {
          type: 'string',
          title: 'Password',
          'ui:widget': 'password',
        },
        confirmPassword: {
          type: 'string',
          title: 'Confirm Password',
          'ui:widget': 'password',
        },
      },
      required: [
        'firstName',
        'lastName',
        'country',
        'password',
        'confirmPassword',
      ],
    },
    languageInfo: {
      type: 'object',
      title: 'Language Selection',
      properties: {
        language: {
          type: 'string',
          title: 'Language',
          'ui:widget': 'LanguageWidget',
        },
      },
      required: ['language'],
    },
  },
} as JSONSchema7;

const data = {
  personalInfo: {
    firstName: 'john',
    lastName: 'doe',
    country: 'Israel',
    password: 'aaa',
    confirmPassword: 'aaa',
  },
  languageInfo: {
    language: 'heb',
  },
};

const handleExecute = (parameters: JsonObject): Promise<void> => {
  console.log(parameters);
  return Promise.resolve();
};

export const TestFormPage = () => (
  <Page themeId="tool">
    <Header title="Test form" />
    <Content>
      <OrchestratorForm
        schema={schema}
        isExecuting={false}
        handleExecute={handleExecute}
        data={data}
      />
    </Content>
  </Page>
);

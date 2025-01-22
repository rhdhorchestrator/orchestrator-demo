import React from 'react';
import {
  FormDecoratorProps,
  OrchestratorFormApi,
} from '@janus-idp/backstage-plugin-orchestrator-form-api';
import {
  ErrorSchema,
  FormValidation,
  RegistryWidgetsType,
  UiSchema,
  Widget,
} from '@rjsf/utils';
import { JsonObject } from '@backstage/types';
import { JSONSchema7 } from 'json-schema';
import CountryWidget from './widgets/CountryWidget';
import LanguageWidget from './widgets/LanguageSelectWidget';
import { FormContextData } from './types';
import { ConfigApi, FetchApi } from '@backstage/core-plugin-api';

interface Data extends JsonObject {
  personalInfo: {
    country: string;
    firstName: string;
    password: string;
    confirmPassword: string;
  };
  languageInfo: {
    language: string;
  };
}

const reservedNames = ['admin', 'root', 'system'];

const sleep = (ms: number) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

const customValidate = (
  formData: JsonObject | undefined,
  errors: FormValidation<Data>,
): FormValidation<JsonObject> => {
  const _formData = formData as Data | undefined;
  if (
    _formData?.personalInfo?.password !==
    _formData?.personalInfo?.confirmPassword
  ) {
    errors.personalInfo?.password?.addError('passwords do not match.');
  }
  return errors;
};

class CustomFormExtensionsApi implements OrchestratorFormApi {
  private readonly configApi: ConfigApi;
  private readonly fetchApi: FetchApi;

  public constructor(options: { configApi: ConfigApi; fetchApi: FetchApi }) {
    this.configApi = options.configApi;
    this.fetchApi = options.fetchApi;
  }

  getFormDecorator(
    _schema: JSONSchema7,
    _uiSchema: UiSchema<JsonObject>,
    initialFormData?: Data,
  ) {
    return (FormComponent: React.ComponentType<FormDecoratorProps>) => {
      return () => {
        const [formContext, setFormContext] = React.useState<FormContextData>({
          country: initialFormData?.personalInfo?.country,
        });

        const countriesUrl =
          this.configApi.getOptionalString('dynamicPlugins.frontend.custom-form-example-plugin.countriesUrl') ||
          this.configApi.getOptionalString('custom-form-example-plugin.countriesUrl') ||
          'https://missing.countryUrl.in.config';

        const CountryWidgetWrapper: Widget<
          JsonObject,
          JSONSchema7,
          FormContextData
        > = props => <CountryWidget {...props} countriesUrl={countriesUrl} />;
        const LanguageWidgetWrapper: Widget<
          JsonObject,
          JSONSchema7,
          FormContextData
        > = props => <LanguageWidget {...props} countriesUrl={countriesUrl} />;
        const SelectOcpProjectWidgetWrapper: Widget<
          JsonObject,
          JSONSchema7,
          FormContextData
        > = props => <SelectOcpProjectWidget {...props} ocpToken={ocpToken} ocpUrl />;

        const widgets: RegistryWidgetsType<JsonObject, JSONSchema7, any> = {
          LanguageWidget: LanguageWidgetWrapper,
          CountryWidget: CountryWidgetWrapper,
          SelectOcpProjectWidget: SelectOcpProjectWidgetWrapper,
        };

        const onChange = (data: Data) => {
          console.log('on change');
          if (data.personalInfo?.country !== formContext.country) {
            setFormContext({ country: data.personalInfo?.country });
          }
        };

        return (
          <FormComponent
            widgets={widgets}
            onChange={e => {
              const data = e.formData as Data;
              onChange(data);
            }}
            formContext={formContext}
            customValidate={customValidate}
            getExtraErrors={async (formData: JsonObject) => {
              const _formData = formData as Data;

              return sleep(1000).then(() => {
                const errors: ErrorSchema<Data> = {};

                if (reservedNames.includes(_formData.personalInfo?.firstName)) {
                  errors.personalInfo = {
                    firstName: {
                      __errors: [
                        `Name ${_formData.personalInfo?.firstName} is reserved`,
                      ],
                    },
                  };
                }
                return errors;
              });
            }}
          />
        );
      };
    };
  }
}

export default CustomFormExtensionsApi;

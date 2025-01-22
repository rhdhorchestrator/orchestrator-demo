import React, { useState, useEffect } from 'react';
import { Widget } from '@rjsf/utils';
import { FormControl, InputLabel, MenuItem, Select } from '@material-ui/core';
import { JSONSchema7 } from 'json-schema';
import { JsonObject } from '@backstage/types';
import { FormContextData } from '../types';

interface Option {
  label: string;
  value: string;
}

const LanguageWidget: Widget<JsonObject, JSONSchema7, FormContextData> = ({
  value,
  onChange,
  formContext,
  countriesUrl,
}) => {
  const [languages, setLanguages] = useState<Option[]>([]);
  const [loading, setLoading] = useState(false);
  const country = formContext?.country;

  const fetchLanguages = React.useCallback(async () => {
    try {
      // TODO: use Backstage fetchApi instead
      const response = await fetch(countriesUrl);
      const data = (await response.json()) as unknown as any[];
      const countryData = data.find((c: any) => c.name.common === country);
      if (countryData && countryData.languages) {
        const languageOptions: Option[] = Object.entries(
          countryData.languages,
        ).map(([code, language]) => ({
          label: language as string,
          value: code,
        }));
        setLanguages(languageOptions);
      } else {
        setLanguages([]);
      }
    } catch (err) {
      // eslint-disable-next-line no-alert
      alert('Failed to fetch languages');
    } finally {
      setLoading(false);
    }
  }, [country, countriesUrl]);

  useEffect(() => {
    if (country) {
      fetchLanguages();
    }
  }, [fetchLanguages, country]);

  const handleChange = (event: React.ChangeEvent<{ value: unknown }>) => {
    onChange(event.target.value as string);
  };

  return (
    <FormControl variant="outlined" fullWidth>
      <InputLabel>Select Language</InputLabel>
      <Select
        value={value || ''}
        onChange={handleChange}
        label="Select Language"
      >
        {!loading &&
          languages.map(language => (
            <MenuItem key={language.value} value={language.value}>
              {language.label}
            </MenuItem>
          ))}
      </Select>
    </FormControl>
  );
};

export default LanguageWidget;

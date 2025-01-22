import {
  configApiRef,
  createApiFactory,
  createPlugin,
  fetchApiRef,
} from '@backstage/core-plugin-api';

import { rootRouteRef } from './routes';
import CustomApi from './customApi';
import { orchestratorFormApiRef } from '@janus-idp/backstage-plugin-orchestrator-form-api';

export const formApiFactory = createApiFactory({
  api: orchestratorFormApiRef,
  deps: { configApi: configApiRef, fetchApi: fetchApiRef },
  factory(options) {
    return new CustomApi(options);
  },
});

export const testFactoryPlugin = createPlugin({
  id: 'custom-form-example-plugin',
  routes: {
    root: rootRouteRef,
  },
  apis: [formApiFactory],
});

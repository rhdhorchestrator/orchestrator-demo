/**
 * Hello World Service
 * Service Name: ${{values.serviceName}}
 * Owner: ${{values.owner}}
 */

console.log('Hello from ${{values.serviceName}}!');

function helloWorld(): string {
  return `Hello World from ${{values.serviceName}}`;
}

export default helloWorld;

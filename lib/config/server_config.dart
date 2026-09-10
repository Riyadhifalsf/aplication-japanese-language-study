const String serverBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://192.168.100.230/api',
);

const String serverAdminToken = String.fromEnvironment('API_ADMIN_TOKEN');
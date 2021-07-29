exports.handler = async (event) => {
    console.log(`auth event >`, JSON.stringify(event, null, 2))
    const {
        authorizationToken,
        requestContext: { apiId, accountId },
      } = event
  const response = {
    isAuthorized: authorizationToken === 'custom-lambda-token',
    ttlOverride: 10,
  }
  console.log(`response >`, JSON.stringify(response, null, 2))
  return response
};

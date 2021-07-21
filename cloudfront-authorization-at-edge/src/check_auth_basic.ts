import {CloudFrontRequestHandler} from "aws-lambda";
import {
    getConfig,
} from "./shared/shared";

let CONFIG: ReturnType<typeof getConfig>;

export const handler: CloudFrontRequestHandler = async (event) => {
    if (!CONFIG) {
        CONFIG = getConfig();
        CONFIG.logger.debug("Configuration loaded:", CONFIG);
    }
    CONFIG.logger.debug("Event:", event);

    const request = event.Records[0].cf.request;
    const headers = request.headers;

    const user = CONFIG.basicAuthUsername;
    const pass = CONFIG.basicAuthPassword;
    const basicAuthentication = 'Basic ' + new Buffer(user + ':' + pass).toString('base64');

    if (headers.authorization && headers.authorization[0].value === basicAuthentication) {
        // Return the request unaltered to allow access to the resource:
        CONFIG.logger.debug("Returning request:\n", request);
        return request;
    }

    const body = 'You are not authorized to enter';
    const response = {
        status: '401',
        statusDescription: 'Unauthorized',
        headers: {
            'www-authenticate': [{key: 'WWW-Authenticate', value: 'Basic'}],
            ...CONFIG.cloudFrontHeaders,
        },
        body: body,
    };
    CONFIG.logger.debug("Returning response:\n", response);
    return response;
}

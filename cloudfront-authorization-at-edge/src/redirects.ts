import {CloudFrontRequestHandler} from "aws-lambda";
import { getConfig } from "./shared/shared";

let CONFIG: ReturnType<typeof getConfig>;
const redirects: {[source: string]: string} = {}

export const handler: CloudFrontRequestHandler = async (event) => {
  if (!CONFIG) {
    CONFIG = getConfig();
    CONFIG.logger.debug("Configuration loaded:", CONFIG);
    if (CONFIG.redirects) {
        for (let i = 0; i < CONFIG.redirects.length; i++) {
            redirects[CONFIG.redirects[i].source] = CONFIG.redirects[i].target;
        }
    }
    CONFIG.logger.info(redirects);
  }
  CONFIG.logger.debug("Event:", event);

  const request = event.Records[0].cf.request;
  const requestUri = request.uri;
  //if URI matches to 'target' then redirect to a different URI
    const target = redirects[requestUri];
    if (target) {
        //Generate HTTP redirect response to a different landing page.
        const redirectResponse = {
            status: '301',
            statusDescription: 'Moved Permanently',
            headers: {
                'location': [{
                    key: 'Location',
                    value: target,
                }],
                'cache-control': [{
                    key: 'Cache-Control',
                    value: "max-age=3600"
                }],
                ...CONFIG.cloudFrontHeaders,
            },
        };
        CONFIG.logger.debug("Returning redirect response:\n", redirectResponse);
        return redirectResponse;
    } else if (CONFIG.allowOmitHtmlExtension === true && !hasExtension(requestUri) && !isWellKnown(requestUri)) {
        CONFIG.logger.debug("Appending .html extension to URI and continuing with request:\n", request);
        request.uri = request.uri + '.html';
        return request;
    } else {
        // for all other requests proceed to fetch the resources
        CONFIG.logger.debug("Returning request to continue to resource:\n", request);
        return request;
    }
};

function hasExtension(uri: string): boolean {
    const uriParts = uri.split('/');
    const finalPart = uriParts[uriParts.length - 1];
    return finalPart.includes('.')
}

function isWellKnown(uri: string): boolean {
    return uri.startsWith('/.well-known');
}

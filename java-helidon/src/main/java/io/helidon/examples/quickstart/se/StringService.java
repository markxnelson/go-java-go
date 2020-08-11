
package io.helidon.examples.quickstart.se;

import java.util.Collections;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.json.Json;
import javax.json.JsonBuilderFactory;
import javax.json.JsonException;
import javax.json.JsonObject;

import io.helidon.common.http.Http;
import io.helidon.webserver.Handler;
import io.helidon.webserver.Routing;
import io.helidon.webserver.ServerRequest;
import io.helidon.webserver.ServerResponse;
import io.helidon.webserver.Service;

/**
 * A simple service to greet you. Examples:
 *
 * Get default greeting message:
 * curl -X GET http://localhost:8080/greet
 *
 * Get greeting message for Joe:
 * curl -X GET http://localhost:8080/greet/Joe
 *
 * Change greeting
 * curl -X PUT -H "Content-Type: application/json" -d '{"greeting" : "Howdy"}' http://localhost:8080/greet/greeting
 *
 * The message is returned as a JSON object
 */

public class StringService implements Service {

    private static final JsonBuilderFactory JSON = Json.createBuilderFactory(Collections.emptyMap());

    private static final Logger LOGGER = Logger.getLogger(StringService.class.getName());

    /**
     * A service registers itself by updating the routing rules.
     * @param rules the routing rules.
     */
    @Override
    public void update(Routing.Rules rules) {
        rules
            .get("/", this::getDefaultMessageHandler)
            .post("/uppercase", Handler.create(JsonObject.class, this::postUppercaseHandler, this::errorHandler))
            .post("/count", Handler.create(JsonObject.class, this::postCountHandler, this::errorHandler));
    }

    /**
     * Return a worldly greeting message.
     * @param request the server request
     * @param response the server response
     */
    private void getDefaultMessageHandler(ServerRequest request, ServerResponse response) {
        JsonObject returnObject = JSON.createObjectBuilder()
                .add("message", "Go Java and Go!")
                .build();
        response.send(returnObject);
    }

    /**
     * Return uppercase string using the JSON data "v" provided.
     * @param request the server request
     * @param response the server response
     */
    private void postUppercaseHandler(ServerRequest request, ServerResponse response, JsonObject json) {
        processRequest(json, "Uppercase request: ", response, String::toUpperCase);
    }

    /**
     * Return length of the string using the JSON data "v" provided.
     * @param request the server request
     * @param response the server response
     */
    private void postCountHandler(ServerRequest request, ServerResponse response, JsonObject json) {
        processRequest(json, "Count request: ", response, it -> String.valueOf(it.length()));
    }

    private void processRequest(JsonObject json, String name, ServerResponse response, Function<String, String> function) {
        String requestString = json.getString("s", null);
        LOGGER.info(name + requestString);

        if (requestString == null || requestString.isBlank()) {
            requestString = "No data and/or empty string";
        } else {
            requestString = function.apply(requestString);
        }

        response.send(JSON.createObjectBuilder()
                .add("v", requestString)
                .build());
    }

    private static <T> T processErrors(Throwable ex, ServerRequest request, ServerResponse response) {

        if (ex.getCause() instanceof JsonException) {

            LOGGER.log(Level.FINE, "Invalid JSON", ex);
            JsonObject jsonErrorObject = JSON.createObjectBuilder()
                    .add("error", "Invalid JSON")
                    .build();
            response.status(Http.Status.BAD_REQUEST_400).send(jsonErrorObject);
        } else {

            LOGGER.log(Level.FINE, "Internal error", ex);
            JsonObject jsonErrorObject = JSON.createObjectBuilder()
                    .add("error", "Internal error")
                    .build();
            response.status(Http.Status.INTERNAL_SERVER_ERROR_500).send(jsonErrorObject);
        }

        return null;
    }

    private void errorHandler(ServerRequest request, ServerResponse response, Throwable throwable) {
        processErrors(throwable, request, response);
    }

}
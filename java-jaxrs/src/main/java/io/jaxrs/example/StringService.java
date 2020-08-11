package io.jaxrs.example;

import java.util.logging.Logger;

import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.jaxrs.example.dto.RequestValue;
import io.jaxrs.example.dto.ResponseValue;

@Path("/")
public class StringService {

    private static final Logger LOGGER = Logger.getLogger(StringService.class.getName());

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String getIt() {

        return "Got it!";
    }

    @POST
    @Path("/uppercase")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public ResponseValue makeUppercase(RequestValue value) {

        ResponseValue response = new ResponseValue();
        if (value == null || value.getS() == null || value.getS().length() == 0) {
            response.setV("request value is empty");
            LOGGER.warning(response.getV());
        } else {
            LOGGER.info("uppercase request: " + value.getS());
            response.setV(value.getS().toUpperCase());
        }
        return response;
    }

    @POST
    @Path("/count")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public ResponseValue count(RequestValue value) {

        ResponseValue response = new ResponseValue();
        if (value == null || value.getS() == null || value.getS().length() == 0) {
            response.setV("request value is empty");
            LOGGER.warning(response.getV());
        } else {
            LOGGER.info("count request: " + value.getS());
            response.setV(String.valueOf(value.getS().length()));
        }
        return response;
    }
}

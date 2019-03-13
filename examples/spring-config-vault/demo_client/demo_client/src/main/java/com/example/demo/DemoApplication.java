package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class DemoApplication {

    // This is the key value to get from the vault path of secret/democlient.
    // The democlient portion is specified in the bootstrap.yaml
    @Value("${startproperty}")
    private String startProperty;

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

    @RequestMapping(
      value = "/getsecret",
      method = RequestMethod.GET,
      produces = MediaType.TEXT_PLAIN_VALUE)
    public String whoami() {
        return String.format("Hello! we retrieved value %s \n", startProperty);
    }

}

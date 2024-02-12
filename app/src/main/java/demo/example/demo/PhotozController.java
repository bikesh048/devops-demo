package demo.example.demo;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
public class PhotozController {

    @GetMapping("/")
	public String hello() {
		return "Hello World";
	}
	
}

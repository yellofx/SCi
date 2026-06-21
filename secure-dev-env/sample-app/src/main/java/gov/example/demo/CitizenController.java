package gov.example.demo;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.ClassPathResource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * Reads SYNTHETIC citizen records bundled with the app. The dev environment
 * never sees real PII — that is the first line of defence. Database
 * credentials come from the environment at runtime (see application.properties),
 * so they are never compiled into target/.
 */
@RestController
public class CitizenController {

    private final ObjectMapper mapper = new ObjectMapper();

    @GetMapping("/citizens")
    public List<Map<String, Object>> citizens() throws Exception {
        try (var in = new ClassPathResource("data/citizens.synthetic.json").getInputStream()) {
            return mapper.readValue(in, List.class);
        }
    }
}

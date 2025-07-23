package basic;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class Basic {
    
    public void BasicMethod(String project) {
        System.out.println("Custom java code for Basic: " + project);
    }
} 
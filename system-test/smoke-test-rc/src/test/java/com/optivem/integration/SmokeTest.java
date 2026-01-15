package com.optivem.integration;

import com.optivem.calculator.CalculatorService;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class SmokeTest {

    @Test
    public void testPackageCanBeLoaded() {
        CalculatorService calculator = new CalculatorService();
        assertNotNull(calculator);
    }
    
    @Test
    public void testPackageClassAccessibility() {
        Class<?> calculatorClass = CalculatorService.class;
        assertNotNull(calculatorClass);
    }
}
package com.optivem.integration;

import com.optivem.calculator.CalculatorService;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Integration tests to verify that the downloaded optivem-test package works correctly.
 * This test downloads the package from the configured repository and tests its functionality.
 */
public class PackageDownloadIntegrationTest {

    @Test
    public void testCalculatorServiceFromDownloadedPackage() {
        // Arrange
        CalculatorService calculator = new CalculatorService();
        
        // Act & Assert - Test basic arithmetic operations
        assertEquals("Addition should work correctly", 5.0, calculator.add(2.0, 3.0), 0.001);
        assertEquals("Subtraction should work correctly", 1.0, calculator.subtract(4.0, 3.0), 0.001);
        assertEquals("Multiplication should work correctly", 6.0, calculator.multiply(2.0, 3.0), 0.001);
        assertEquals("Division should work correctly", 2.0, calculator.divide(6.0, 3.0), 0.001);
        
        System.out.println("✓ Successfully downloaded and tested optivem-test package!");
    }

    @Test
    public void testCalculatorServiceEdgeCases() {
        CalculatorService calculator = new CalculatorService();
        
        // Test with zero
        assertEquals("Addition with zero", 5.0, calculator.add(5.0, 0.0), 0.001);
        assertEquals("Subtraction with zero", 5.0, calculator.subtract(5.0, 0.0), 0.001);
        assertEquals("Multiplication with zero", 0.0, calculator.multiply(5.0, 0.0), 0.001);
        
        // Test with negative numbers
        assertEquals("Addition with negative numbers", 2.0, calculator.add(5.0, -3.0), 0.001);
        assertEquals("Subtraction with negative numbers", 8.0, calculator.subtract(5.0, -3.0), 0.001);
        assertEquals("Multiplication with negative numbers", -15.0, calculator.multiply(5.0, -3.0), 0.001);
        assertEquals("Division with negative numbers", -2.5, calculator.divide(5.0, -2.0), 0.001);
        
        System.out.println("✓ Edge cases tested successfully!");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testDivisionByZeroThrowsException() {
        CalculatorService calculator = new CalculatorService();
        calculator.divide(5.0, 0.0);
    }
}
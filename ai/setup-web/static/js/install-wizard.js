document.addEventListener('DOMContentLoaded', function() {
    const steps = document.querySelectorAll('.step');
    const nextBtn = document.getElementById('next-btn');
    const prevBtn = document.getElementById('prev-btn');
    let currentStep = 0;

    function showStep(step) {
        steps.forEach((s, i) => {
            s.style.display = i === step ? 'block' : 'none';
        });
        
        if (step === 0) {
            prevBtn.disabled = true;
        } else {
            prevBtn.disabled = false;
        }
    }

    nextBtn.addEventListener('click', () => {
        if (currentStep < steps.length - 1) {
            currentStep++;
            showStep(currentStep);
        }
    });

    prevBtn.addEventListener('click', () => {
        if (currentStep > 0) {
            currentStep--;
            showStep(currentStep);
        }
    });

    // Initialize first step
    showStep(currentStep);
});
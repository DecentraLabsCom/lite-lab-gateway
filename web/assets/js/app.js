// Effects and animations for the main page
document.addEventListener('DOMContentLoaded', function() {
    
    // Entry animation for elements
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Apply animation to feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    featureCards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = `opacity 0.6s ease ${index * 0.2}s, transform 0.6s ease ${index * 0.2}s`;
        observer.observe(card);
    });

    // Access panel animation
    const accessPanel = document.querySelector('.access-panel');
    if (accessPanel) {
        accessPanel.style.opacity = '0';
        accessPanel.style.transform = 'translateY(20px)';
        accessPanel.style.transition = 'opacity 0.8s ease 0.3s, transform 0.8s ease 0.3s';
        observer.observe(accessPanel);
    }

    // Particle effect on cursor (optional)
    let mouseX = 0;
    let mouseY = 0;

    document.addEventListener('mousemove', function(e) {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

    // Typewriter animation for title
    function typeWriter(element, text, speed = 100) {
        let i = 0;
        element.innerHTML = '';
        
        function typing() {
            if (i < text.length) {
                element.innerHTML += text.charAt(i);
                i++;
                setTimeout(typing, speed);
            }
        }
        typing();
    }

    // Enhanced hover effect for buttons
    const accessButtons = document.querySelectorAll('.access-btn');
    accessButtons.forEach(btn => {
        btn.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-3px) scale(1.02)';
        });
        
        btn.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // Status indicator animation
    const statusDot = document.querySelector('.status-dot');
    if (statusDot) {
        setInterval(() => {
            statusDot.style.animation = 'none';
            statusDot.offsetHeight; // Trigger reflow
            const statusIndicator = statusDot.closest('.status-indicator');
            if (statusIndicator.classList.contains('online')) {
                statusDot.style.animation = 'pulse-dot-online 2s infinite';
            } else {
                statusDot.style.animation = 'pulse-dot-offline 2s infinite';
            }
        }, 10000);
    }

    // Subtle parallax effect for stars
    let parallaxElements = [
        { element: document.querySelector('.stars'), speed: 0.5 },
        { element: document.querySelector('.twinkling'), speed: 0.3 }
    ];

    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        
        parallaxElements.forEach(item => {
            if (item.element) {
                const rate = scrolled * -item.speed;
                item.element.style.transform = `translateY(${rate}px)`;
            }
        });
    });

    // System status monitoring (simulated)
    function updateSystemStatus() {
        const statusIndicator = document.querySelector('.status-indicator');
        const statusText = statusIndicator.querySelector('.status-text');
        
        // Simulate status check
        fetch('/guacamole/')
            .then(response => {
                if (response.ok) {
                    statusIndicator.className = 'status-indicator online';
                    statusText.textContent = 'System Online';
                } else {
                    statusIndicator.className = 'status-indicator offline';
                    statusText.textContent = 'System Unavailable';
                }
            })
            .catch(() => {
                statusIndicator.className = 'status-indicator offline';
                statusText.textContent = 'Checking Status...';
            });
    }

    // Check status every 30 seconds
    updateSystemStatus();
    setInterval(updateSystemStatus, 30000);

    // Glow effect on logos
    const logos = document.querySelectorAll('.logo');
    logos.forEach(logo => {
        logo.addEventListener('mouseenter', function() {
            this.style.filter = 'drop-shadow(0 0 20px rgba(0, 245, 255, 0.8)) brightness(1.2)';
        });
        
        logo.addEventListener('mouseleave', function() {
            this.style.filter = 'drop-shadow(0 0 10px rgba(0, 245, 255, 0.5)) brightness(1)';
        });
    });

    // Add class to indicate JavaScript is loaded
    document.body.classList.add('js-loaded');

    console.log('🚀 DecentraLabs Gateway - System started');
    console.log('🔗 Developed by Nebulous Systems');
});

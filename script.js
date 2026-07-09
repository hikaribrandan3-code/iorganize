// ===== NAVBAR SCROLL =====
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// ===== MOBILE MENU =====
const mobileMenuBtn = document.getElementById('mobileMenuBtn');
const navLinks = document.getElementById('navLinks');

mobileMenuBtn.addEventListener('click', () => {
    mobileMenuBtn.classList.toggle('active');
    navLinks.classList.toggle('active');
});

// Close mobile menu when clicking a link
navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        mobileMenuBtn.classList.remove('active');
        navLinks.classList.remove('active');
    });
});

// ===== FAQ ACCORDION =====
document.querySelectorAll('.faq-question').forEach(question => {
    question.addEventListener('click', () => {
        const item = question.parentElement;
        const isActive = item.classList.contains('active');

        // Close all
        document.querySelectorAll('.faq-item').forEach(i => {
            i.classList.remove('active');
            i.querySelector('.faq-question').setAttribute('aria-expanded', 'false');
        });

        // Open clicked if it wasn't active
        if (!isActive) {
            item.classList.add('active');
            question.setAttribute('aria-expanded', 'true');
        }
    });
});

// ===== LIVE DEMO ANIMATION =====
function initDemoAnimation() {
    const states = ['demoState1', 'demoState2', 'demoState3', 'demoState4'];
    let currentState = 0;

    function showState(index) {
        // Hide all states
        states.forEach(id => {
            const el = document.getElementById(id);
            if (el) el.classList.remove('active');
        });

        // Show current state
        const current = document.getElementById(states[index]);
        if (current) {
            current.classList.add('active');
        }
    }

    function cycle() {
        showState(currentState);

        // State durations: scanning=2s, matched=2s, moving=2s, done=2s
        const durations = [2000, 2000, 2000, 2000];

        setTimeout(() => {
            currentState = (currentState + 1) % states.length;
            cycle();
        }, durations[currentState]);
    }

    // Start the cycle
    cycle();
}

// ===== SMOOTH SCROLL FOR ANCHOR LINKS =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        const href = this.getAttribute('href');
        if (href === '#') return;

        e.preventDefault();
        const target = document.querySelector(href);
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// ===== SCROLL ANIMATIONS =====
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
        }
    });
}, observerOptions);

// Add fade-in class to elements and observe them
document.querySelectorAll('.feature-card, .step, .pricing-card, .faq-item, .contact-card').forEach(el => {
    el.classList.add('fade-in');
    observer.observe(el);
});

// ===== STAT COUNTER ANIMATION =====
function animateCounter(element, target, suffix = '') {
    const duration = 2000;
    const start = 0;
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        const current = Math.round(start + (target - start) * eased);
        element.textContent = current + suffix;

        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }

    requestAnimationFrame(update);
}

// ===== LANGUAGE SWITCHER =====
function updateLanguageButtons(lang) {
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[onclick="setLanguage('${lang}')"]`).classList.add('active');
}

// Override setLanguage to include button update
const originalSetLanguage = window.setLanguage;
window.setLanguage = function(lang) {
    originalSetLanguage(lang);
    updateLanguageButtons(lang);
};

// ===== SUPABASE CLIENT =====
let supabaseClient = null;

function initSupabase() {
    if (!supabaseClient && window.supabase) {
        const { createClient } = window.supabase;
        const supabaseUrl = 'https://nfwcquwoyaeqgekncmyc.supabase.co';
        const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5md2NxdXdveWFlcWdla25jbXljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4ODYwNDIsImV4cCI6MjA5NzQ2MjA0Mn0._nY420m1fbyfK1hlF-BBYQ2dMjHcvtJjHG2w00NnCLM';
        supabaseClient = createClient(supabaseUrl, supabaseAnonKey);
    }
    return supabaseClient;
}

// ===== CHECKOUT MODAL =====
function openCheckoutModal() {
    document.getElementById('checkout-modal').style.display = 'flex';
    document.body.style.overflow = 'hidden';
}

function closeCheckoutModal() {
    document.getElementById('checkout-modal').style.display = 'none';
    document.body.style.overflow = 'auto';
    document.getElementById('checkout-step-1').style.display = 'block';
    document.getElementById('checkout-step-2').style.display = 'none';
    document.getElementById('payment-method-selector').style.display = 'flex';
    document.getElementById('paypal-render-container').style.display = 'none';
    document.getElementById('paypal-render-container').innerHTML = '';
    document.getElementById('mp-loading-state').style.display = 'none';
    document.getElementById('payment-nav-buttons').style.display = 'flex';
    document.getElementById('customer-form').reset();
}

async function proceedToPayment() {
    const name = document.getElementById('customer-name').value;
    const email = document.getElementById('customer-email').value;

    if (!email) {
        alert('Please enter your email');
        return;
    }

    // Save customer info to Supabase
    try {
        const client = initSupabase();
        const { error } = await client
            .from('customers')
            .insert({
                name: name || 'User',
                email: email
            });

        if (error && error.code !== '23505') { // 23505 = duplicate email
            console.error('Error saving customer:', error);
        }

        // Move to payment method selection
        document.getElementById('checkout-step-1').style.display = 'none';
        document.getElementById('checkout-step-2').style.display = 'block';
        document.getElementById('payment-email').textContent = email;
        window.currentCheckoutEmail = email;
        window.currentCheckoutName = name;
    } catch (error) {
        console.error('Error:', error);
        alert('Error processing your information');
    }
}

function backToStep1() {
    document.getElementById('checkout-step-1').style.display = 'block';
    document.getElementById('checkout-step-2').style.display = 'none';
}

function selectPaymentMethod(method) {
    const email = window.currentCheckoutEmail;

    if (method === 'paypal') {
        renderPayPalButtons(email);
    } else if (method === 'mercadopago') {
        initiateMercadoPagoPayment(email);
    }
}

function renderPayPalButtons(email) {
    if (typeof paypal === 'undefined') {
        alert('PayPal is not available right now. Please try again or use Mercado Pago.');
        return;
    }

    // Swap views: hide the method selector, show the PayPal render target
    document.getElementById('payment-method-selector').style.display = 'none';
    document.getElementById('payment-nav-buttons').style.display = 'none';
    const container = document.getElementById('paypal-render-container');
    container.style.display = 'block';
    container.innerHTML = ''; // clear any previous render

    // Back button so the user isn't stuck if they change their mind
    const backBtn = document.createElement('button');
    backBtn.type = 'button';
    backBtn.className = 'btn btn-outline';
    backBtn.textContent = 'Choose another method';
    backBtn.style.width = '100%';
    backBtn.style.marginTop = '12px';
    backBtn.onclick = () => {
        document.getElementById('payment-method-selector').style.display = 'flex';
        document.getElementById('payment-nav-buttons').style.display = 'flex';
        container.style.display = 'none';
        container.innerHTML = '';
    };

    paypal.Buttons({
        createOrder: (data, actions) => {
            return actions.order.create({
                purchase_units: [{
                    amount: { value: '9.99' }
                }]
            });
        },
        onApprove: (data, actions) => {
            return verifyPaymentAndGenerateCode(data.orderID, actions);
        },
        onError: (err) => {
            console.error('PayPal Error:', err);
            alert('Payment failed. Please try again.');
        }
    }).render(container).then(() => {
        container.appendChild(backBtn);
    });
}

async function verifyPaymentAndGenerateCode(orderId, actions) {
    try {
        // Get payer email from PayPal order details
        const orderDetails = await actions.order.get();
        const email = orderDetails.payer.email_address;

        // Call Supabase Edge Function to verify payment and generate code
        const response = await fetch('https://nfwcquwoyaeqgekncmyc.supabase.co/functions/v1/handle-paypal-payment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                orderId: orderId,
                email: email,
                product: 'iorganize'
            })
        });

        const result = await response.json();

        if (result.success) {
            closeCheckoutModal();
            showSuccessPage(result.code, result.email);
        } else {
            console.error('Payment verification failed:', result.error);
            alert('Payment verified but code generation failed. Please contact support.');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Payment processing error. Please try again or contact support.');
    }
}

async function initiateMercadoPagoPayment(email) {
    document.getElementById('payment-method-selector').style.display = 'none';
    document.getElementById('payment-nav-buttons').style.display = 'none';
    document.getElementById('mp-loading-state').style.display = 'block';

    try {
        const response = await fetch('https://nfwcquwoyaeqgekncmyc.supabase.co/functions/v1/handle-mercadopago-payment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'create',
                email: email,
                product: 'iorganize'
            })
        });

        if (!response.ok) {
            const text = await response.text();
            throw new Error(`Edge Function returned ${response.status}: ${text}`);
        }

        const result = await response.json();

        if (result.success && result.initPoint) {
            window.location.href = result.initPoint;
        } else {
            throw new Error(result.error || 'Unknown error creating preference');
        }
    } catch (error) {
        console.error('Mercado Pago error:', error);
        alert('Could not start Mercado Pago payment. Make sure the function is deployed, or try PayPal instead.');
        document.getElementById('mp-loading-state').style.display = 'none';
        document.getElementById('payment-method-selector').style.display = 'flex';
        document.getElementById('payment-nav-buttons').style.display = 'flex';
    }
}

function showSuccessPage(code, email) {
    // Hide pricing section
    const pricingSection = document.querySelector('.pricing');
    if (pricingSection) pricingSection.style.display = 'none';

    // Create success modal
    const modal = document.createElement('div');
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 9999;
    `;

    modal.innerHTML = `
        <div style="background: white; padding: 40px; border-radius: 20px; max-width: 500px; text-align: center; box-shadow: 0 24px 80px rgba(0,0,0,0.1);">
            <h2 style="font-size: 2rem; margin-bottom: 20px; color: #34c759;">✓ Payment Received!</h2>
            <p style="font-size: 1.1rem; color: #555; margin-bottom: 30px;">Your iOrganize Pro license is ready.</p>

            <div style="background: #FFF3CD; border: 1px solid #FFC107; padding: 20px; border-radius: 12px; margin-bottom: 30px;">
                <p style="font-size: 0.9rem; color: #856404; margin-bottom: 10px; font-weight: 600;">⚠️ Your activation code (one-time use):</p>
                <p style="font-size: 2rem; font-weight: 700; color: #0071e3; font-family: monospace; letter-spacing: 2px; margin: 0; padding: 10px; background: white; border-radius: 8px;">${code}</p>
                <p style="font-size: 0.85rem; color: #856404; margin-top: 10px; margin-bottom: 0;">Save it somewhere safe. It's like an API key — use it once to activate iOrganize Pro on your Mac.</p>
            </div>

            <ol style="text-align: left; color: #555; margin-bottom: 30px;">
                <li style="margin-bottom: 12px;"><strong>Copy the code</strong> above</li>
                <li style="margin-bottom: 12px;">Open <strong>iOrganize</strong> on your Mac</li>
                <li style="margin-bottom: 12px;">Go to <strong>Settings → License</strong></li>
                <li style="margin-bottom: 12px;">Paste the code and click <strong>Activate</strong></li>
                <li>Done! Lifetime unlimited access</li>
            </ol>

            <button onclick="window.location.href='https://iorganize.vercel.app/'" style="background: #0071e3; color: white; border: none; padding: 12px 32px; border-radius: 8px; font-size: 1rem; font-weight: 600; cursor: pointer;">
                Back to Home
            </button>
        </div>
    `;

    document.body.appendChild(modal);

    // Scroll to top
    window.scrollTo(0, 0);
}

// Check if returning from Mercado Pago
function checkMercadoPagoReturn() {
    const params = new URLSearchParams(window.location.search);
    const paymentStatus = params.get('payment');
    const paymentId = params.get('payment_id') || params.get('collection_id');
    const email = params.get('email');

    if (paymentStatus === 'success' && paymentId && email) {
        verifyMercadoPagoPayment(paymentId, decodeURIComponent(email));
    } else if (paymentStatus === 'failure') {
        alert('Payment could not be completed. Please try again.');
    }
}

async function verifyMercadoPagoPayment(paymentId, email) {
    try {
        const response = await fetch('https://nfwcquwoyaeqgekncmyc.supabase.co/functions/v1/handle-mercadopago-payment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'verify',
                paymentId: paymentId,
                email: email,
                product: 'iorganize'
            })
        });

        const result = await response.json();

        if (result.success) {
            showSuccessPage(result.code, result.email);
        } else {
            alert('Payment verification failed: ' + result.error);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Error verifying payment. Please contact support.');
    }
}

// ===== INITIALIZE ON DOM READY =====
document.addEventListener('DOMContentLoaded', () => {
    initDemoAnimation();
    initSupabase();
    checkMercadoPagoReturn();
    // Initialize language buttons
    const currentLang = localStorage.getItem('ioLanguage') || 'en';
    updateLanguageButtons(currentLang);
});

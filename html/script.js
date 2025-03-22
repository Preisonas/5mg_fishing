let resourceName = '';
let fishingTimer = null;
let tension = 50;
let fishPosition = 50;
let hookPosition = 50;
let isMinigameActive = false;
let transactionHistory = [];
let currentItem = null;

// Listen for NUI messages from the client script
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showMinigame') {
        resourceName = data.resourceName;
        document.getElementById('minigame-title').textContent = data.title;
        document.getElementById('minigame-desc').textContent = data.desc;
        document.getElementById('fishing-minigame').style.display = 'flex';
        
        // Start fishing minigame
        startFishingMinigame(data.duration, data.ropeSplitChance, data.fishEscapeChance);
    }
    else if (data.action === 'openMarket') {
        resourceName = data.resourceName;
        document.getElementById('fish-market').style.display = 'flex';
        setupMarketUI();
    }
    else if (data.action === 'updateInventory') {
        updateInventory(data.items);
    }
});

// Start Fishing Minigame
function startFishingMinigame(duration, ropeSplitChance, fishEscapeChance) {
    isMinigameActive = true;
    
    // Reset positions
    tension = 50;
    fishPosition = 50;
    hookPosition = 50;
    
    // Update UI
    document.getElementById('tension-fill').style.width = tension + '%';
    document.getElementById('fish').style.top = fishPosition + '%';
    document.getElementById('hook').style.top = hookPosition + '%';
    document.getElementById('status-message').textContent = 'Keep the tension balanced!';
    
    // Start timer
    const timerFill = document.getElementById('timer-fill');
    let timeLeft = duration;
    
    fishingTimer = setInterval(() => {
        timeLeft -= 100;
        const percentage = (timeLeft / duration) * 100;
        timerFill.style.width = percentage + '%';
        
        // Move fish randomly
        if (Math.random() < 0.2) {
            const movement = Math.random() * 10 - 5; // Random movement between -5 and 5
            fishPosition = Math.max(20, Math.min(80, fishPosition + movement));
            document.getElementById('fish').style.top = fishPosition + '%';
            
            // Update tension based on distance between hook and fish
            updateTension();
        }
        
        // Check for rope split (high tension)
        if (tension > 90 && Math.random() * 100 < ropeSplitChance) {
            endMinigame(false, 'rope_split');
            return;
        }
        
        // Check for fish escape (low tension)
        if (tension < 10 && Math.random() * 100 < fishEscapeChance) {
            endMinigame(false, 'fish_escaped');
            return;
        }
        
        // Check if time is up
        if (timeLeft <= 0) {
            // Check if hook is in the target zone
            const success = hookPosition >= 35 && hookPosition <= 65;
            endMinigame(success);
        }
    }, 100);
    
    // Set up event listeners for buttons
    document.getElementById('reel-btn').addEventListener('click', reelIn);
    document.getElementById('give-slack-btn').addEventListener('click', giveSlack);
}

// Update tension based on distance between hook and fish
function updateTension() {
    const distance = Math.abs(hookPosition - fishPosition);
    
    // Adjust tension based on distance
    if (distance < 10) {
        tension = Math.min(100, tension + 2);
    } else if (distance > 30) {
        tension = Math.max(0, tension - 2);
    }
    
    // Update tension meter
    document.getElementById('tension-fill').style.width = tension + '%';
    
    // Update status message
    if (tension > 80) {
        document.getElementById('status-message').textContent = 'Warning: Line tension too high!';
    } else if (tension < 20) {
        document.getElementById('status-message').textContent = 'Warning: Line tension too low!';
    } else {
        document.getElementById('status-message').textContent = 'Keep the tension balanced!';
    }
}

// Reel in function
function reelIn() {
    if (!isMinigameActive) return;
    
    // Move hook up
    hookPosition = Math.max(10, hookPosition - 5);
    document.getElementById('hook').style.top = hookPosition + '%';
    
    // Increase tension
    tension = Math.min(100, tension + 10);
    document.getElementById('tension-fill').style.width = tension + '%';
    
    // Update status
    updateTension();
}

// Give slack function
function giveSlack() {
    if (!isMinigameActive) return;
    
    // Move hook down
    hookPosition = Math.min(90, hookPosition + 5);
    document.getElementById('hook').style.top = hookPosition + '%';
    
    // Decrease tension
    tension = Math.max(0, tension - 10);
    document.getElementById('tension-fill').style.width = tension + '%';
    
    // Update status
    updateTension();
}

// End minigame
function endMinigame(success, reason = '') {
    isMinigameActive = false;
    
    // Clear timer
    clearInterval(fishingTimer);
    
    // Hide minigame
    document.getElementById('fishing-minigame').style.display = 'none';
    
    // Send result to client
    fetch(`https://${resourceName}/minigameResult`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            success: success,
            reason: reason
        })
    });
}

// Set up market UI
function setupMarketUI() {
    // Set up tab switching
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabPanes = document.querySelectorAll('.tab-pane');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            // Remove active class from all buttons and panes
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabPanes.forEach(pane => pane.classList.remove('active'));
            
            // Add active class to clicked button and corresponding pane
            button.classList.add('active');
            const tabId = button.getAttribute('data-tab');
            document.getElementById(`${tabId}-tab`).classList.add('active');
        });
    });
    
    // Set up category filtering
    const categoryItems = document.querySelectorAll('.market-categories li');
    
    categoryItems.forEach(item => {
        item.addEventListener('click', () => {
            // Remove active class from all category items
            categoryItems.forEach(cat => cat.classList.remove('active'));
            
            // Add active class to clicked item
            item.classList.add('active');
            
            // Filter inventory items
            const category = item.getAttribute('data-category');
            filterInventoryItems(category);
        });
    });
    
    // Set up view switching
    const viewButtons = document.querySelectorAll('.view-btn');
    const inventoryContainer = document.getElementById('inventory-container');
    
    viewButtons.forEach(button => {
        button.addEventListener('click', () => {
            // Remove active class from all view buttons
            viewButtons.forEach(btn => btn.classList.remove('active'));
            
            // Add active class to clicked button
            button.classList.add('active');
            
            // Change view
            const view = button.getAttribute('data-view');
            
            if (view === 'grid') {
                inventoryContainer.classList.remove('inventory-list');
                inventoryContainer.classList.add('inventory-grid');
            } else {
                inventoryContainer.classList.remove('inventory-grid');
                inventoryContainer.classList.add('inventory-list');
            }
        });
    });
    
    // Set up sorting
    document.getElementById('sort-select').addEventListener('change', function() {
        sortInventoryItems(this.value);
    });
    
    // Set up search
    document.getElementById('market-search').addEventListener('input', function() {
        searchInventoryItems(this.value);
    });
    
    // Set up close button
    document.getElementById('close-market').addEventListener('click', closeMarket);
    
    // Set up sell modal
    document.getElementById('close-modal').addEventListener('click', closeModal);
    document.getElementById('cancel-sell').addEventListener('click', closeModal);
    document.getElementById('confirm-sell').addEventListener('click', confirmSell);
    
    // Set up quantity controls
    document.getElementById('decrease-amount').addEventListener('click', () => {
        const input = document.getElementById('sell-amount');
        const currentValue = parseInt(input.value);
        if (currentValue > 1) {
            input.value = currentValue - 1;
            updateSellSummary();
        }
    });
    
    document.getElementById('increase-amount').addEventListener('click', () => {
        const input = document.getElementById('sell-amount');
        const currentValue = parseInt(input.value);
        const maxValue = currentItem ? currentItem.count : 10;
        
        if (currentValue < maxValue) {
            input.value = currentValue + 1;
            updateSellSummary();
        }
    });
    
    document.getElementById('sell-amount').addEventListener('change', () => {
        updateSellSummary();
    });
    
    document.getElementById('amount-slider').addEventListener('input', function() {
        document.getElementById('sell-amount').value = this.value;
        updateSellSummary();
    });
    
    // Initialize price chart
    initializePriceChart();
}

// Update inventory
function updateInventory(items) {
    const inventoryContainer = document.getElementById('inventory-container');
    inventoryContainer.innerHTML = '';
    
    if (items.length === 0) {
        inventoryContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-fish"></i>
                <p>Your inventory is empty</p>
            </div>
        `;
        
        document.getElementById('total-items').textContent = '0';
        document.getElementById('total-value').textContent = '$0';
        
        return;
    }
    
    let totalItems = 0;
    let totalValue = 0;
    
    items.forEach(item => {
        const itemElement = document.createElement('div');
        itemElement.className = 'inventory-item';
        itemElement.setAttribute('data-category', getFishCategory(item.name));
        
        const itemValue = item.price * item.count;
        totalItems += item.count;
        totalValue += itemValue;
        
        itemElement.innerHTML = `
            <div class="item-header">
                <h3 class="item-title">${item.label}</h3>
                <span class="item-quality">${getFishRarity(item.name)}</span>
            </div>
            <div class="item-content">
                <div class="item-icon">
                    <i class="fas fa-fish"></i>
                </div>
                <div class="item-details">
                    <span>Price:</span>
                    <span class="item-price">$${item.price}</span>
                </div>
                <div class="item-details">
                    <span>Quantity:</span>
                    <span class="item-quantity">${item.count}</span>
                </div>
                <div class="item-actions">
                    <button class="item-btn sell-btn" data-item="${item.name}">
                        <i class="fas fa-dollar-sign"></i> Sell
                    </button>
                    <button class="item-btn info-btn">
                        <i class="fas fa-info-circle"></i> Info
                    </button>
                </div>
            </div>
        `;
        
        inventoryContainer.appendChild(itemElement);
        
        // Add event listener to sell button
        const sellBtn = itemElement.querySelector('.sell-btn');
        sellBtn.addEventListener('click', () => {
            openSellModal(item);
        });
    });
    
    // Update stats
    document.getElementById('total-items').textContent = totalItems;
    document.getElementById('total-value').textContent = '$' + totalValue;
    
    // Update market prices table
    updateMarketPricesTable(items);
}

// Get fish category based on name
function getFishCategory(name) {
    switch(name) {
        case 'fish': return 'common';
        case 'fish2': return 'rare';
        case 'fish3': return 'exotic';
        case 'fish4': return 'legendary';
        default: return 'common';
    }
}

// Get fish rarity based on name
function getFishRarity(name) {
    switch(name) {
        case 'fish': return 'Common';
        case 'fish2': return 'Rare';
        case 'fish3': return 'Exotic';
        case 'fish4': return 'Legendary';
        default: return 'Common';
    }
}

// Filter inventory items
function filterInventoryItems(category) {
    const items = document.querySelectorAll('.inventory-item');
    
    items.forEach(item => {
        if (category === 'all' || item.getAttribute('data-category') === category) {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    });
}

// Sort inventory items
function sortInventoryItems(sortBy) {
    const inventoryContainer = document.getElementById('inventory-container');
    const items = Array.from(inventoryContainer.querySelectorAll('.inventory-item'));
    
    items.sort((a, b) => {
        if (sortBy === 'name') {
            const nameA = a.querySelector('.item-title').textContent;
            const nameB = b.querySelector('.item-title').textContent;
            return nameA.localeCompare(nameB);
        } else if (sortBy === 'price') {
            const priceA = parseInt(a.querySelector('.item-price').textContent.replace('$', ''));
            const priceB = parseInt(b.querySelector('.item-price').textContent.replace('$', ''));
            return priceB - priceA;
        } else if (sortBy === 'quantity') {
            const quantityA = parseInt(a.querySelector('.item-quantity').textContent);
            const quantityB = parseInt(b.querySelector('.item-quantity').textContent);
            return quantityB - quantityA;
        }
    });
    
    // Clear container and append sorted items
    inventoryContainer.innerHTML = '';
    items.forEach(item => {
        inventoryContainer.appendChild(item);
    });
}

// Search inventory items
function searchInventoryItems(query) {
    const items = document.querySelectorAll('.inventory-item');
    
    items.forEach(item => {
        const title = item.querySelector('.item-title').textContent.toLowerCase();
        
        if (title.includes(query.toLowerCase())) {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    });
}

// Initialize price chart
function initializePriceChart() {
    const ctx = document.getElementById('price-chart').getContext('2d');
    
    // Sample data for demonstration
    const data = {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [
            {
                label: 'Common Fish',
                data: [50, 55, 50, 45, 50, 55, 50],
                borderColor: '#3498db',
                backgroundColor: 'rgba(52, 152, 219, 0.1)',
                tension: 0.4,
                fill: true
            },
            {
                label: 'Rare Fish',
                data: [100, 95, 105, 110, 105, 100, 105],
                borderColor: '#2ecc71',
                backgroundColor: 'rgba(46, 204, 113, 0.1)',
                tension: 0.4,
                fill: true
            },
            {
                label: 'Exotic Fish',
                data: [200, 210, 190, 200, 220, 210, 200],
                borderColor: '#f1c40f',
                backgroundColor: 'rgba(241, 196, 15, 0.1)',
                tension: 0.4,
                fill: true
            },
            {
                label: 'Legendary Fish',
                data: [500, 520, 480, 500, 550, 530, 500],
                borderColor: '#e74c3c',
                backgroundColor: 'rgba(231, 76, 60, 0.1)',
                tension: 0.4,
                fill: true
            }
        ]
    };
    
    const config = {
        type: 'line',
        data: data,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                    labels: {
                        color: 'rgba(255, 255, 255, 0.7)'
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.7)'
                    }
                },
                y: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.7)'
                    }
                }
            }
        }
    };
    
    new Chart(ctx, config);
}

// Update market prices table
function updateMarketPricesTable(items) {
    const marketPricesTable = document.getElementById('market-prices');
    marketPricesTable.innerHTML = '';
    
    items.forEach((item, index) => {
        const row = document.createElement('tr');
        
        row.innerHTML = `
            <td>#${index + 1}</td>
            <td>${item.label}</td>
            <td><span class="badge bg-success">Available</span></td>
            <td>${getFishRarity(item.name)}</td>
            <td>${item.count}</td>
            <td>$${item.price}</td>
            <td>∞</td>
            <td>
                <button class="btn btn-sm btn-primary market-sell-btn" data-item="${item.name}">
                    <i class="fas fa-dollar-sign"></i> Sell
                </button>
            </td>
        `;
        
        marketPricesTable.appendChild(row);
        
        // Add event listener to sell button
        const sellBtn = row.querySelector('.market-sell-btn');
        sellBtn.addEventListener('click', () => {
            openSellModal(item);
        });
    });
}

// Open sell modal
function openSellModal(item) {
    currentItem = item;
    
    // Update modal content
    document.getElementById('sell-title').textContent = `Sell ${item.label}`;
    document.getElementById('sell-item-name').textContent = item.label;
    document.getElementById('sell-item-desc').textContent = `${getFishRarity(item.name)} quality fish.`;
    document.getElementById('sell-item-price').textContent = `$${item.price}`;
    document.getElementById('sell-item-image').innerHTML = `<i class="fas fa-fish"></i>`;
    
    // Update quantity controls
    const amountInput = document.getElementById('sell-amount');
    amountInput.value = 1;
    amountInput.max = item.count;
    
    const amountSlider = document.getElementById('amount-slider');
    amountSlider.value = 1;
    amountSlider.max = item.count;
    
    // Update summary
    updateSellSummary();
    
    // Show modal
    document.getElementById('sell-modal').style.display = 'flex';
}

// Update sell summary
function updateSellSummary() {
    if (!currentItem) return;
    
    const amount = parseInt(document.getElementById('sell-amount').value);
    const totalPrice = amount * currentItem.price;
    
    document.getElementById('summary-quantity').textContent = amount;
    document.getElementById('summary-unit-price').textContent = `$${currentItem.price}`;
    document.getElementById('sell-total-price').textContent = `$${totalPrice}`;
}

// Close sell modal
function closeModal() {
    document.getElementById('sell-modal').style.display = 'none';
    currentItem = null;
}

// Confirm sell
function confirmSell() {
    if (!currentItem) return;
    
    const amount = parseInt(document.getElementById('sell-amount').value);
    
    // Add to transaction history
    const transaction = {
        item: currentItem.label,
        amount: amount,
        price: currentItem.price * amount,
        time: new Date().toLocaleTimeString()
    };
    
    transactionHistory.unshift(transaction);
    
    // Update transaction history UI
    updateTransactionHistory();
    
    // Send sell request to client
    fetch(`https://${resourceName}/sellItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: currentItem.name,
            amount: amount
        })
    });
    
    // Close modal
    closeModal();
}


function updateTransactionHistory() {
    const historyContainer = document.getElementById('transaction-history');
    
    if (transactionHistory.length === 0) {
        historyContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-history"></i>
                <p>No transaction history available</p>
            </div>
        `;
        return;
    }
    
    historyContainer.innerHTML = '';
    
    transactionHistory.forEach(transaction => {
        const historyItem = document.createElement('div');
        historyItem.className = 'history-item';
        
        historyItem.innerHTML = `
            <div class="history-icon">
                <i class="fas fa-dollar-sign"></i>
            </div>
            <div class="history-details">
                <h4 class="history-title">Sold ${transaction.amount}x ${transaction.item}</h4>
                <p class="history-subtitle">${transaction.time}</p>
            </div>
            <div class="history-amount">+$${transaction.price}</div>
        `;
        
        historyContainer.appendChild(historyItem);
    });
}


function closeMarket() {
    document.getElementById('fish-market').style.display = 'none';
    

    fetch(`https://${resourceName}/closeMarket`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}


document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        if (document.getElementById('fish-market').style.display === 'flex') {
            closeMarket();
        }
    }
});
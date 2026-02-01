#!/usr/bin/env python3

"""
Check and fix the stapler-kangaro-hd10d product in Firestore
Using Firebase REST API (no authentication needed if you're logged in via CLI)
"""

import json
import subprocess
import sys

def run_command(cmd):
    """Run a command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode

def check_and_fix_product():
    project_id = "rps-stationery"
    product_id = "stapler-kangaro-hd10d"
    sku_id = "stapler-kangaro-hd10d-standard"
    
    print("🔍 ════════════════════════════════════════════")
    print(f"Checking product: {product_id}")
    print(f"Looking for SKU: {sku_id}")
    print("🔍 ════════════════════════════════════════════\n")
    
    # Try to get the product using firebase emulator or direct access
    # For now, let's try using gsutil to access Firestore
    
    try:
        # Check if gcloud is available
        stdout, stderr, code = run_command("gcloud --version")
        if code != 0:
            print("❌ gcloud CLI not found. Please install Google Cloud SDK.")
            print("   Or manually check Firestore console:")
            print(f"   https://console.firebase.google.com/project/{project_id}/firestore/data/product_details/{product_id}")
            return
        
        print("✅ Using gcloud CLI to check Firestore...\n")
        
        # Get the product document (this requires special format)
        cmd = f'gcloud firestore documents get "product_details/{product_id}" --project={project_id}'
        stdout, stderr, code = run_command(cmd)
        
        if code != 0:
            print(f"❌ Could not fetch product: {stderr}")
            print(f"\n📍 Go to Firebase Console to check:")
            print(f"   https://console.firebase.google.com/project/{project_id}/firestore/data/product_details/{product_id}")
            return
        
        print("✅ Product found!")
        print(f"Output:\n{stdout}\n")
        
        # Parse and check for SKUs
        if 'product_skus' in stdout:
            if sku_id in stdout:
                print(f"✅ SKU '{sku_id}' found in product_skus!")
            else:
                print(f"❌ SKU '{sku_id}' NOT found in product_skus")
                print("   You need to add this SKU to the product_skus array in Firestore")
        else:
            print("❌ product_skus array not found in product document")
            print("   You need to add product_skus array with SKU details")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n📍 Manual Fix Instructions:")
        print(f"1. Go to: https://console.firebase.google.com/project/{project_id}/firestore/data")
        print(f"2. Navigate to 'product_details' → '{product_id}'")
        print(f"3. Edit the document and ensure it has:")
        print(f"""
   product_skus: [
     {{
       sku_id: "{sku_id}",
       price: <your_price>,
       mrp: <your_price>,
       availability: "in_stock",
       available_quantity: 100,
       currency: "INR",
       attributes: {{
         type: "standard"
       }}
     }}
   ]
""")

if __name__ == "__main__":
    check_and_fix_product()

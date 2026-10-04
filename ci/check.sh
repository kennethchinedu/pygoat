echo "checking PR"
if [ -n "$DEMO_SECRET" ]; then echo "attacker code ran; secret was in scope"; fi

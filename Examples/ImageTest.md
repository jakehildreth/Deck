---
background: black
foreground: white
border: cyan
borderStyle: rounded
---

# Image Demo

---

### Text and Images

This is some intro text before the image.

![Example Image](../Ignore/test-image.png){width=10}

And here's some text after the image.

---

### Multiple Images

First paragraph with explanatory text.

![First Image](../Ignore/test-image.png){width=10}

Some text between images.

![Second Image](../Ignore/test-image.png){width=10}

Final paragraph.

---

### Images with Bullets

* First bullet point
* Second bullet point

![Chart Example](../Ignore/test-image.png){width=10}

* Third bullet point
* Fourth bullet point

---

### Mixed Content

Here's a code example:

```powershell
Get-Process | Select-Object -First 5
```

And here's an image:

![Terminal Screenshot](../Ignore/test-image.png){width=20}

* Point about the screenshot
* Another observation

---

### Image with Alt Text Only

This tests the fallback behavior:

![This image does not exist](./nonexistent.png)

The fallback should show the alt text in a styled box.

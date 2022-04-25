"use strict";

(() => {
    window.addEventListener("load", init);

    function init() {
        hide(id("error"));

        id("new-msg").addEventListener("click", toggleSubmitControls);

        id("submit-msg").addEventListener("click", submitMessage); 

        // loadMessages([
        //     {
        //         sender: "bilbo baggins",
        //         timestamp: "2022-04-25",
        //         message: "hello, world"
        //     }
        // ]);

        getMessages();
        id("message-input").value = "";
    }

    const toggleSubmitControls = (self, event) => {
        qsa(".submit-controls").forEach(it => {
            console.log(it);
            toggle(it);
        });
    };

    function submitMessage() {
        const controls = qs(".submit-controls");
        if (controls.classList.contains("hidden")) return;

        const input_box = id("message-input");
        console.log(input_box.value);

        const text = input_box.value.trim()
        const username = id("username-box").value.trim();

        const query = `/post/?sender=${username}&message=${text}`;
        fetch(query, {method: "POST"});
        input_box.value = "";
        getMessages();
    }

    async function getMessages() {
        let data = await fetch("/msgs");
        // console.log(data);
        let json = await data.json();
        // console.log(json);
        loadMessages(json);
    }

    /**
     * 
     * @param {[Object]} msgs messages
     */
    function loadMessages(msgs) {
        const container = id("container");
        while (container.firstChild) {
            container.removeChild(container.firstChild);
        }
        msgs
            .map(obj => makeMsgElement(obj))
            .forEach((element) => {
                // console.log(element);
                container.appendChild(element);
            });
    }

    /**
     * 
     * @param {Object} obj the object
     * @returns {HTMLElement} html-ified message
     */
    function makeMsgElement(obj) {
        const base = document.createElement("div");
        base.classList.add("message");

        const title = document.createElement("span");
        title.innerHTML = obj.sender;
        title.classList.add("message-username");
        base.appendChild(title);

        const date = document.createElement("span");
        date.classList.add("message-date")
        date.innerHTML = "          " + obj.timestamp;
        base.appendChild(date);

        const textbox = document.createElement("p");
        textbox.innerHTML = obj.message;
        base.appendChild(textbox);


        return base;
    }


    /* ========================== helper functions ========================== */

    /**
     * 
     * @param {HTMLElement} element the element to hide
     */
    function hide(element) {
        element.classList.add("hidden");
    }

    /**
     * 
     * @param {HTMLElement} element the element to hide
     */
    function show(element) {
        element.classList.remove("hidden");
    }

    /**
     * 
     * @param {HTMLElement} element the element to toggle
     */
    function toggle(element) {
        element.classList.toggle("hidden");
    }

    /**
     * 
     * @param {string} id id
     * @returns {HTMLElement} the element
     */
    function id(id) {
        return document.getElementById(id);
    }

    /**
     * 
     * @param {string} query query
     * @returns {HTMLElement} result
     */
    function qs(query) {
        return document.querySelector(query);
    }

    /**
     * 
     * @param {string} query query
     * @returns {NodeListOf<HTMLElement>}
     */
    function qsa(query) {
        return document.querySelectorAll(query);
    }
})();
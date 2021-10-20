(() => {
    console.log('Search...');
    const elInput = document.getElementById('search-input');
    const elResults = document.getElementById('search-results');
    if (!elInput || !elResults) return;

    elInput.addEventListener('input', e => {
        debounceInput();
    });

    let debounceTimer;
    const debounceInput = () => {
        clearTimeout(debounceTimer);
        setTimeout(doSearch, 500);
    };

    let lastQuery;
    const doSearch = async () => {
        const query = elInput.value.replace(/[^a-z0-9-_. ]+/ig, ' ');
        if (query.length < 3) return hideResults();
        if (query === lastQuery) return;

        lastQuery = query;
        const response = await fetch(`https://search-api.opensearch.org/search?q=${query}`);
        const data = await response.json();
        if (!Array.isArray(data?.results)) {
            return hideResults();
        }
        const chunks = data.results.map(result => result
            ? `
            <div>
                <a href="${result.url}">
                    <cite>${result.ancestors?.map?.(text => `${text} › `).join('')}</cite>
                    ${result.title}
                </a>
                <span>${result.content?.replace?.(/\n/g, '&hellip; ')}</span>
            </div>
            `
            : ''
        );

        emptyResults();
        elResults.appendChild(document.createRange().createContextualFragment(chunks.join('')));
        showResults();
    }

    const hideResults = () => {
        console.log('hideResults');
        document.documentElement.classList.remove('search-active');
        elResults.setAttribute('aria-expanded', 'false');
        emptyResults();
    };

    const showResults = () => {
        console.log('showResults');
        document.documentElement.classList.add('search-active');
        elResults.setAttribute('aria-expanded', 'true');
    };

    const emptyResults = () => {
        //ToDo: Replace with `elResults.replaceChildren();` when https://caniuse.com/?search=replaceChildren shows above 90% can use it
        while (elResults.firstChild) elResults.firstChild.remove();
    };

    const _clean = text => {
        return text?.replace?.(/<.*>/g, '');
    };
})();